import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:braand_app/models/leave_balance.dart';
import 'package:braand_app/models/leave_request.dart';

class LeaveService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submit a new leave request
  Future<void> submitLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String reason,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('leave_requests').insert({
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'leave_type': leaveType,
      'reason': reason,
      'status': 'Pending',
    });

    // Update pending leaves
    try {
      final days = endDate.difference(startDate).inDays + 1;
      final year = startDate.year;

      final balance = await getLeaveBalance(userId, year);
      await _supabase.from('leave_balances').update({
        'pending_leaves': balance.pendingLeaves + days,
      }).eq('id', balance.id);
    } catch (e) {
      debugPrint('⚠️ Error updating pending leaves: $e');
    }
  }

  /// Get leave balance for a user and year
  Future<LeaveBalance> getLeaveBalance(String userId, int year) async {
    try {
      final response = await _supabase
          .from('leave_balances')
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .maybeSingle();

      if (response == null) {
        // Initialize default
        final newBalance = await _supabase
            .from('leave_balances')
            .insert({
              'user_id': userId,
              'year': year,
              'total_leaves': 12,
              'used_leaves': 0,
              'pending_leaves': 0,
            })
            .select()
            .single();
        return LeaveBalance.fromJson(newBalance);
      }
      return LeaveBalance.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting leave balance: $e');
      return LeaveBalance(id: '', userId: userId, year: year);
    }
  }

  /// Get leave requests for the current user
  Future<List<LeaveRequest>> getMyLeaveRequests() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('leave_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => LeaveRequest.fromJson(json)).toList();
  }

  /// Get all leave requests (Admin only)
  Future<List<LeaveRequest>> getAllLeaveRequests() async {
    final response = await _supabase
        .from('admin_leave_requests_view')
        .select()
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => LeaveRequest.fromJson(json)).toList();
  }

  /// Update leave request status (Admin only)
  Future<void> updateLeaveStatus({
    required String requestId,
    required String status,
    String? adminComment,
  }) async {
    try {
      // Fetch request first to get details
      final requestData = await _supabase
          .from('leave_requests')
          .select()
          .eq('id', requestId)
          .single();
      final LeaveRequest request = LeaveRequest.fromJson(requestData);

      await _supabase.from('leave_requests').update({
        'status': status,
        'admin_comment': adminComment,
      }).eq('id', requestId);

      // Update Leave Balance
      if (status == 'Approved' && request.status != 'Approved') {
        final days = request.endDate.difference(request.startDate).inDays + 1;
        final year = request.startDate.year;
        final balance = await getLeaveBalance(request.userId, year);

        await _supabase.from('leave_balances').update({
          'used_leaves': balance.usedLeaves + days,
          'pending_leaves': (balance.pendingLeaves - days) < 0
              ? 0
              : (balance.pendingLeaves - days),
        }).eq('id', balance.id);
      } else if (status == 'Rejected' && request.status == 'Pending') {
        final days = request.endDate.difference(request.startDate).inDays + 1;
        final year = request.startDate.year;
        final balance = await getLeaveBalance(request.userId, year);

        await _supabase.from('leave_balances').update({
          'pending_leaves': (balance.pendingLeaves - days) < 0
              ? 0
              : (balance.pendingLeaves - days),
        }).eq('id', balance.id);
      }
    } catch (e) {
      debugPrint('❌ Error updating leave status: $e');
      rethrow;
    }
  }

  /// Stream leave requests for the current user (Real-time)
  Stream<List<LeaveRequest>> streamMyLeaveRequests() {
    return _supabase
        .from('leave_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .map(
            (data) => data.map((json) => LeaveRequest.fromJson(json)).toList());
  }

  /// Stream all leave requests for Admin (Real-time)
  Stream<List<LeaveRequest>> streamAllLeaveRequests() {
    return _supabase
        .from('leave_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((_) async => await getAllLeaveRequests());
  }
}

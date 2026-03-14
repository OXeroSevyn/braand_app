import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  /// Create a new user profile
  Future<void> createProfile(app_models.User user) async {
    await _supabase.from('profiles').insert({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'department': user.department,
      'avatar_url': user.avatarUrl,
      'status': 'pending', // Default status for new signups
    });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 Sending password reset email to: $email');
      const redirectUrl =
          kIsWeb ? null : 'io.supabase.braandapp://login-callback';

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );
      debugPrint('✅ Password reset email sent (Redirect: $redirectUrl)');
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('🔐 Updating password...');
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('✅ Password updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      rethrow;
    }
  }

  /// Get all active employees
  Future<List<app_models.User>> getAllEmployees() async {
    debugPrint('📡 Fetching all active employees...');
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('role', 'Employee')
        .eq('status', 'active'); // Only fetch active employees

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} active employees from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  /// Get all admins
  Future<List<app_models.User>> getAllAdmins() async {
    debugPrint('📡 Fetching all admins...');
    final response =
        await _supabase.from('profiles').select().eq('role', 'Admin');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} admins from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  /// Get users with pending status
  Future<List<app_models.User>> getPendingUsers() async {
    debugPrint('📡 Fetching pending users...');
    final response =
        await _supabase.from('profiles').select().eq('status', 'pending');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} pending users from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  /// Get users with rejected status
  Future<List<app_models.User>> getRejectedUsers() async {
    debugPrint('📡 Fetching rejected users...');
    final response =
        await _supabase.from('profiles').select().eq('status', 'rejected');

    final List<dynamic> data = response as List<dynamic>;
    debugPrint('📡 Received ${data.length} rejected users from DB');
    return data.map((json) => app_models.User.fromJson(json)).toList();
  }

  /// Update user account status (pending, active, rejected)
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      debugPrint('🔄 Updating user status: $userId -> $status');
      final response = await _supabase
          .from('profiles')
          .update({'status': status})
          .eq('id', userId)
          .select();

      if ((response as List).isEmpty) {
        throw Exception('Update failed: No rows updated. Check RLS policies.');
      }

      debugPrint('✅ User status updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
      rethrow;
    }
  }

  /// Invite a user (Placeholder for edge function call)
  Future<void> inviteUser({
    required String email,
    required String role,
    required String department,
    required String name,
  }) async {
    // Current flow relies on user signup + admin approval.
    // Future implementation could use Supabase Edge Functions.
  }

  /// Get profile data for a specific user
  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return app_models.User.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String userId, String token) async {
    await _supabase
        .from('profiles')
        .update({'fcm_token': token}).eq('id', userId);
  }

  /// Update user profile details
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? department,
    String? bio,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (department != null) updates['department'] = department;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', userId);
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Reset points and task completion counts for all users (Admin action)
  Future<void> resetAllUserPoints() async {
    try {
      debugPrint('🔄 Resetting points and tasks for all users...');
      await _supabase.from('profiles').update({
        'points': 0,
        'tasks_completed': 0,
      }).neq('id', '00000000-0000-0000-0000-000000000000'); // Update all
      debugPrint('✅ All user points reset successfully');
    } catch (e) {
      debugPrint('❌ Error resetting user points: $e');
      rethrow;
    }
  }

  /// Upload profile picture to storage
  Future<String?> uploadProfilePicture(Uint8List bytes, String userId) async {
    try {
      debugPrint('📸 Starting profile picture upload for user: $userId');
      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('📸 Uploading to bucket: profile-pictures, file: $fileName');
      await _supabase.storage
          .from('profile-pictures')
          .uploadBinary(fileName, bytes);

      final url =
          _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      debugPrint('✅ Profile picture uploaded successfully: $url');
      return url;
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading profile picture: $e');
      debugPrint('Stack trace: $stackTrace');

      if (e.toString().contains('Bucket not found') ||
          e.toString().contains('bucket') ||
          e.toString().contains('404')) {
        debugPrint(
            '💡 Hint: Create "profile-pictures" bucket in Supabase Storage');
      }

      return null;
    }
  }
}

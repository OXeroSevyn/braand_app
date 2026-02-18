import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/supabase_service.dart';
import '../models/leave_request.dart';
import '../models/leave_balance.dart';
import '../widgets/neo_card.dart';

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> _updateStatus(LeaveRequest request, String status) async {
    final commentController = TextEditingController();
    bool confirmed = false;

    // If rejecting, require a comment
    if (status == 'Rejected') {
      confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Reject Request', style: GoogleFonts.spaceGrotesk()),
              content: TextField(
                controller: commentController,
                decoration: const InputDecoration(
                    labelText: 'Reason for rejection',
                    hintText: 'e.g., Critical project deadline'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('REJECT'),
                ),
              ],
            ),
          ) ??
          false;
    } else {
      // Approve confirmation
      confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Approve Request', style: GoogleFonts.spaceGrotesk()),
              content: Text(
                  'Approve ${request.userName}\'s leave for ${request.leaveType}?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand),
                  child: const Text('APPROVE'),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (confirmed) {
      try {
        await _supabaseService.updateLeaveStatus(
          requestId: request.id,
          status: status,
          adminComment:
              commentController.text.isNotEmpty ? commentController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request $status')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<LeaveRequest>>(
      stream: _supabaseService.streamAllLeaveRequests(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data ?? [];
        final pending =
            allRequests.where((r) => r.status == 'Pending').toList();
        final approved =
            allRequests.where((r) => r.status == 'Approved').toList();
        final rejected =
            allRequests.where((r) => r.status == 'Rejected').toList();

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'LEAVE REQUESTS',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              bottom: TabBar(
                labelColor: AppColors.brand,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.brand,
                tabs: [
                  Tab(text: 'PENDING (${pending.length})'),
                  Tab(text: 'APPROVED (${approved.length})'),
                  Tab(text: 'REJECTED (${rejected.length})'),
                ],
              ),
            ),
            body: snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.hasError
                    ? Center(
                        child: Text(
                          'Error loading leaves',
                          style: GoogleFonts.spaceMono(color: Colors.red),
                        ),
                      )
                    : TabBarView(
                        children: [
                          _buildList(pending, true),
                          _buildList(approved, false),
                          _buildList(rejected, false),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<LeaveRequest> requests, bool showActions) {
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'No requests found',
          style: GoogleFonts.spaceMono(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final duration = req.endDate.difference(req.startDate).inDays + 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NeoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.brand,
                      child: Text(
                        req.userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.userName ?? 'Unknown User',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // Role and Balance
                          Row(
                            children: [
                              Text(
                                req.userRole ?? 'Employee',
                                style: GoogleFonts.spaceMono(
                                    color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              FutureBuilder<LeaveBalance>(
                                future: _supabaseService.getLeaveBalance(
                                    req.userId, req.startDate.year),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final bal = snapshot.data!;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bal.remaining > 0
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Bal: ${bal.remaining}/${bal.totalLeaves}',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: bal.remaining > 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        req.leaveType,
                        style: GoogleFonts.spaceMono(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd').format(req.endDate)}',
                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($duration days)',
                      style: GoogleFonts.spaceMono(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reason: ${req.reason ?? "None"}',
                  style: GoogleFonts.spaceMono(),
                ),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(req, 'Rejected'),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('REJECT',
                            style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(req, 'Approved'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('APPROVE',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

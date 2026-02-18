import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../services/supabase_service.dart';
import '../models/leave_request.dart';
import '../models/leave_balance.dart';
import '../widgets/neo_card.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  LeaveBalance? _balance;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final balance = await _supabaseService.getLeaveBalance(
            user.id, DateTime.now().year);
        if (mounted) {
          setState(() {
            _balance = balance;
            _isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _showApplyLeaveDialog() async {
    final reasonController = TextEditingController();
    DateTimeRange? dateRange;
    String selectedType = 'Sick';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Apply for Leave',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['Sick', 'Casual', 'Annual', 'Unpaid']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: GoogleFonts.spaceMono()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedType = value!),
                  decoration: const InputDecoration(labelText: 'Leave Type'),
                  style: GoogleFonts.spaceMono(color: Colors.black),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    dateRange == null
                        ? 'Select Dates'
                        : '${DateFormat('MMM dd').format(dateRange!.start)} - ${DateFormat('MMM dd').format(dateRange!.end)}',
                    style: GoogleFonts.spaceMono(),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => dateRange = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Reason is required' : null,
                  style: GoogleFonts.spaceMono(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.spaceMono()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate() && dateRange != null) {
                  Navigator.pop(context);
                  try {
                    await _supabaseService.submitLeaveRequest(
                      startDate: dateRange!.start,
                      endDate: dateRange!.end,
                      leaveType: selectedType,
                      reason: reasonController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Leave request submitted')),
                      );
                      // Stream will auto-update
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                } else if (dateRange == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select dates')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand),
              child: Text('SUBMIT',
                  style: GoogleFonts.spaceMono(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildBalanceCard() {
    if (_isLoadingBalance) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_balance == null) return const SizedBox.shrink();

    return NeoCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LEAVE BALANCE ${DateTime.now().year}',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.pie_chart, color: AppColors.brand, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  'Total', _balance!.totalLeaves.toString(), Colors.blue),
              _buildStatItem(
                  'Used', _balance!.usedLeaves.toString(), Colors.orange),
              _buildStatItem(
                  'Remaining', _balance!.remaining.toString(), Colors.green,
                  isBig: true),
            ],
          ),
          if (_balance!.pendingLeaves > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pending Approval: ${_balance!.pendingLeaves} days',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color,
      {bool isBig = false}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: isBig ? 28 : 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY LEAVES',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      ),
      body: StreamBuilder<List<LeaveRequest>>(
        stream: _supabaseService.streamMyLeaveRequests(),
        builder: (context, snapshot) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildBalanceCard(),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading leaves',
                          style: GoogleFonts.spaceMono(color: Colors.red),
                        ),
                      );
                    }

                    final requests = snapshot.data ?? [];

                    if (requests.isEmpty) {
                      return Center(
                        child: Text(
                          'No leave history',
                          style: GoogleFonts.spaceMono(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final duration =
                            req.endDate.difference(req.startDate).inDays + 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: NeoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Chip(
                                      label: Text(
                                        req.leaveType.toUpperCase(),
                                        style: GoogleFonts.spaceMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor:
                                          AppColors.brand.withOpacity(0.2),
                                      labelStyle:
                                          TextStyle(color: AppColors.brand),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(req.status)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _getStatusColor(req.status)),
                                      ),
                                      child: Text(
                                        req.status.toUpperCase(),
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(req.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${DateFormat('MMM dd').format(req.startDate)} - ${DateFormat('MMM dd, yyyy').format(req.endDate)}',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '($duration days)',
                                      style: GoogleFonts.spaceMono(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (req.reason != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    req.reason!,
                                    style: GoogleFonts.spaceMono(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey[800]),
                                  ),
                                ],
                                if (req.adminComment != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Admin: ${req.adminComment}',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyLeaveDialog,
        backgroundColor: AppColors.brand,
        label: Text('APPLY LEAVE',
            style: GoogleFonts.spaceMono(color: Colors.black)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

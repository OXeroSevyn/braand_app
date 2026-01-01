import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/supabase_service.dart';
import '../services/auto_signout_service.dart';
import '../widgets/neo_card.dart';

class OfficeHoursSettingsScreen extends StatefulWidget {
  const OfficeHoursSettingsScreen({super.key});

  @override
  State<OfficeHoursSettingsScreen> createState() =>
      _OfficeHoursSettingsScreenState();
}

class _OfficeHoursSettingsScreenState extends State<OfficeHoursSettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  TimeOfDay _inTime = const TimeOfDay(hour: 10, minute: 30);
  TimeOfDay _outTime = const TimeOfDay(hour: 20, minute: 0);
  bool _sundayOff = true;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOfficeHours();
  }

  Future<void> _loadOfficeHours() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _supabaseService.getOfficeHours();
      if (settings != null && mounted) {
        setState(() {
          _inTime = _parseTime(settings['in_time']);
          _outTime = _parseTime(settings['out_time']);
          _sundayOff = settings['sunday_off'] ?? true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Future<void> _pickTime(BuildContext context, bool isInTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isInTime ? _inTime : _outTime,
    );

    if (picked != null) {
      setState(() {
        if (isInTime) {
          _inTime = picked;
        } else {
          _outTime = picked;
        }
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _supabaseService.updateOfficeHours(
        inTime: _inTime,
        outTime: _outTime,
        sundayOff: _sundayOff,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Office hours updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Office Hours Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.brand, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFICE HOURS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Set global office hours for all employees',
                          style: GoogleFonts.spaceMono(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Current Hours Display
                  NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'CURRENT HOURS',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  'IN TIME',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTimeOfDay(_inTime),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward,
                                color: Colors.grey[400], size: 32),
                            Column(
                              children: [
                                Text(
                                  'OUT TIME',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTimeOfDay(_outTime),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Pickers
                  NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.edit_calendar, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'CONFIGURE HOURS',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // In Time Selector
                        _buildTimeSelector(
                          label: 'Office In Time',
                          time: _inTime,
                          onTap: () => _pickTime(context, true),
                          icon: Icons.login,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Out Time Selector
                        _buildTimeSelector(
                          label: 'Office Out Time',
                          time: _outTime,
                          onTap: () => _pickTime(context, false),
                          icon: Icons.logout,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),

                        // Sunday Off Toggle
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.weekend,
                                      size: 20,
                                      color:
                                          isDark ? Colors.white : Colors.black),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sunday Off',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Office closed on Sundays',
                                        style: GoogleFonts.spaceMono(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Switch(
                                value: _sundayOff,
                                onChanged: (value) {
                                  setState(() => _sundayOff = value);
                                },
                                activeColor: AppColors.brand,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Card
                  NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 20, color: AppColors.brand),
                            const SizedBox(width: 8),
                            Text(
                              'IMPORTANT INFO',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '• Employees cannot sign in/out outside these hours',
                        ),
                        _buildInfoItem(
                          '• System auto-signs-out employees at end time',
                        ),
                        _buildInfoItem(
                          '• Office is closed on Sundays (if enabled)',
                        ),
                        _buildInfoItem(
                          '• Changes apply immediately to all employees',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: isDark ? Colors.white : Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'SAVE OFFICE HOURS',
                              style: GoogleFonts.spaceMono(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Manual Trigger Button (Debug)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _triggerAutoSignOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(
                            color: isDark ? Colors.white : Colors.black,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'TRIGGER AUTO SIGN-OUT NOW (DEBUG)',
                        style: GoogleFonts.spaceMono(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Future<void> _triggerAutoSignOut() async {
    setState(() => _isLoading = true);
    try {
      // Import this at the top of the file: import '../services/auto_signout_service.dart';
      final service = AutoSignOutService();
      final logs = await service.triggerNow(); // We will add this method next

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Auto Sign-Out Report'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: logs.map((log) {
                    Color color = Colors.black;
                    if (log.contains('❌') || log.contains('⚠️'))
                      color = Colors.red;
                    if (log.contains('✅') || log.contains('🟢'))
                      color = Colors.green;
                    if (log.contains('🚀')) color = Colors.blue;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error triggering: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.brand),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  _formatTimeOfDay(time),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

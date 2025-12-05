import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/notification_setting.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../widgets/neo_card.dart';
import '../widgets/neo_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();

  List<NotificationSetting> _settings = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getNotificationSettings();
      setState(() {
        _settings =
            data.map((json) => NotificationSetting.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      for (final setting in _settings) {
        await _supabaseService.updateNotificationSetting(
          id: setting.id,
          enabled: setting.enabled,
          time: setting.time,
          message: setting.message,
          daysOfWeek: setting.daysOfWeek,
        );
      }

      // Re-schedule notifications with new settings
      await _notificationService.scheduleNotificationsFromSettings(_settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Settings saved successfully!',
              style: GoogleFonts.spaceMono(),
            ),
            backgroundColor: AppColors.brand,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving settings: $e',
              style: GoogleFonts.spaceMono(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.showTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test notification sent!',
              style: GoogleFonts.spaceMono(),
            ),
            backgroundColor: AppColors.brand,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending test notification: $e',
              style: GoogleFonts.spaceMono(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    final canSchedule = await _notificationService.canScheduleExactAlarms();

    if (mounted) {
      if (canSchedule) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Exact alarm permission granted',
              style: GoogleFonts.spaceMono(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show dialog to request permission
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exact Alarm Permission',
              style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'This app needs exact alarm permission to send notifications at the scheduled times. Would you like to grant this permission?',
              style: GoogleFonts.spaceMono(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: GoogleFonts.spaceMono()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Grant', style: GoogleFonts.spaceMono()),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          final granted =
              await _notificationService.requestExactAlarmPermission();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  granted ? '✅ Permission granted' : '❌ Permission denied',
                  style: GoogleFonts.spaceMono(),
                ),
                backgroundColor: granted ? Colors.green : Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showSendCustomMessageDialog() async {
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Custom Message',
          style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will send an immediate notification to all employees.',
              style: GoogleFonts.spaceMono(fontSize: 11),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: GoogleFonts.spaceMono(fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.spaceMono(fontSize: 12),
                hintText: 'Enter your message here...',
                hintStyle: GoogleFonts.spaceMono(fontSize: 11),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.spaceMono()),
          ),
          NeoButton(
            text: 'SEND',
            onPressed: () => Navigator.pop(context, true),
            color: AppColors.brand,
            textColor: Colors.black,
          ),
        ],
      ),
    );

    if (result == true && messageController.text.isNotEmpty) {
      try {
        // Send custom notification via Supabase
        await SupabaseService().sendCustomNotification(
          title: 'Braand Attendance',
          message: messageController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Custom message sent to all employees!',
                style: GoogleFonts.spaceMono(),
              ),
              backgroundColor: AppColors.brand,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error sending message: $e',
                style: GoogleFonts.spaceMono(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NOTIFICATION SETTINGS',
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: _checkExactAlarmPermission,
            tooltip: 'Check Alarm Permission',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _showSendCustomMessageDialog,
            tooltip: 'Send Custom Message',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: _sendTestNotification,
            tooltip: 'Send Test Notification',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info Card
                  NeoCard(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Configure notification reminders for employees',
                            style: GoogleFonts.spaceMono(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Settings Cards
                  ..._settings.map((setting) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSettingCard(setting, isDark),
                      )),

                  const SizedBox(height: 24),

                  // Save Button
                  NeoButton(
                    text: 'SAVE SETTINGS',
                    onPressed: _saveSettings,
                    isLoading: _isSaving,
                    color: AppColors.brand,
                    textColor: Colors.black,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingCard(NotificationSetting setting, bool isDark) {
    return NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(
                _getIconForType(setting.type),
                size: 24,
                color: setting.enabled ? AppColors.brand : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  setting.displayName,
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: setting.enabled,
                onChanged: (value) {
                  setState(() {
                    final index = _settings.indexOf(setting);
                    _settings[index] = setting.copyWith(enabled: value);
                  });
                },
                activeColor: AppColors.brand,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Picker
          Row(
            children: [
              const Icon(Icons.access_time, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Time:',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _selectTime(setting),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    setting.time,
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Message Input
          TextField(
            controller: TextEditingController(text: setting.message),
            onChanged: (value) {
              final index = _settings.indexOf(setting);
              _settings[index] = setting.copyWith(message: value);
            },
            style: GoogleFonts.spaceMono(fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: GoogleFonts.spaceMono(fontSize: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Days of Week
          Text(
            'Days:',
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
                .map((day) => _buildDayChip(setting, day, isDark))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(NotificationSetting setting, String day, bool isDark) {
    final isSelected = setting.daysOfWeek.contains(day);

    return InkWell(
      onTap: () {
        setState(() {
          final index = _settings.indexOf(setting);
          final newDays = List<String>.from(setting.daysOfWeek);

          if (isSelected) {
            newDays.remove(day);
          } else {
            newDays.add(day);
          }

          _settings[index] = setting.copyWith(daysOfWeek: newDays);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand : Colors.transparent,
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
        child: Text(
          day.toUpperCase(),
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : null,
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(NotificationSetting setting) async {
    final timeParts = setting.time.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        final index = _settings.indexOf(setting);
        final timeString =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _settings[index] = setting.copyWith(time: timeString);
      });
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'clock_in':
        return Icons.login;
      case 'clock_out':
        return Icons.logout;
      case 'break_reminder':
        return Icons.coffee;
      case 'custom_message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }
}

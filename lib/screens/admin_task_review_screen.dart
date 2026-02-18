import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../constants.dart';
import '../widgets/neo_card.dart';
import '../widgets/user_avatar.dart';

class AdminTaskReviewScreen extends StatefulWidget {
  final User employee;

  const AdminTaskReviewScreen({super.key, required this.employee});

  @override
  State<AdminTaskReviewScreen> createState() => _AdminTaskReviewScreenState();
}

class _AdminTaskReviewScreenState extends State<AdminTaskReviewScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedDate = DateTime.now();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _supabaseService.getUserTasksForDate(
        widget.employee.id,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateAssessment(Task task, String assessment) async {
    try {
      await _supabaseService.updateTaskAssessment(task.id, assessment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task marked as ${assessment.toUpperCase()}')),
        );
        _loadTasks(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updatePriority(Task task, String priority) async {
    try {
      await _supabaseService.updateTaskPriority(task.id, priority);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Priority set to ${priority.toUpperCase()}')),
        );
        _loadTasks(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TASK REVIEW',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: widget.employee.avatar,
                  name: widget.employee.name,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employee.name,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.employee.department,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      _loadTasks();
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                ),
              ],
            ),
          ),

          // Date Display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Text(
                          'No tasks found for this date',
                          style: GoogleFonts.spaceMono(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return _buildTaskCard(task, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    Color statusColor = Colors.grey;
    if (task.adminAssessment == 'accepted') statusColor = Colors.green;
    if (task.adminAssessment == 'rejected') statusColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeoCard(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted && isDark ? Colors.grey : null,
                    ),
                  ),
                ),
                if (task.priority == 'urgent')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'URGENT',
                      style: GoogleFonts.spaceMono(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task.description!,
                  style: GoogleFonts.roboto(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: task.isCompleted ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  task.isCompleted ? 'Completed' : 'Pending',
                  style: GoogleFonts.spaceMono(
                    fontSize: 12,
                    color: task.isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.adminAssessment.toUpperCase(),
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Admin Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.check,
                  label: 'Accept',
                  color: Colors.green,
                  isSelected: task.adminAssessment == 'accepted',
                  onTap: () => _updateAssessment(task, 'accepted'),
                ),
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Reject',
                  color: Colors.red,
                  isSelected: task.adminAssessment == 'rejected',
                  onTap: () => _updateAssessment(task, 'rejected'),
                ),
                _buildActionButton(
                  icon: Icons.priority_high,
                  label: 'Urgent',
                  color: Colors.orange,
                  isSelected: task.priority == 'urgent',
                  onTap: () => _updatePriority(
                      task, task.priority == 'urgent' ? 'normal' : 'urgent'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models/monthly_task.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../widgets/liquid_progress_bar.dart';
import '../widgets/neo_card.dart';

class EmployeeTasksScreen extends StatefulWidget {
  final User user;

  const EmployeeTasksScreen({super.key, required this.user});

  @override
  State<EmployeeTasksScreen> createState() => _EmployeeTasksScreenState();
}

class _EmployeeTasksScreenState extends State<EmployeeTasksScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Task> _tasks = [];
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // Monthly tasks
  List<Map<String, dynamic>> _monthlyTasks = [];
  // Daily tasks
  List<MonthlyTask> _dailyTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _supabaseService.getUserTasksForDate(
        widget.user.id,
        _selectedDate,
      );
      // Load monthly tasks for current month
      final monthlyTasks = await _supabaseService.getMonthlyTasks(
        month: DateTime.now().month,
        year: DateTime.now().year,
        userId: widget.user.id,
      );
      // Load daily tasks for selected date
      final dailyTasksData = await _supabaseService.getDailyTasks(
        date: _selectedDate,
        userId: widget.user.id,
      );
      final dailyTasks =
          dailyTasksData.map((task) => MonthlyTask.fromJson(task)).toList();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _monthlyTasks = monthlyTasks;
          _dailyTasks = dailyTasks;
        });
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _addTask() async {
    final title = _taskTitleController.text.trim();
    final description = _taskDescriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final task = Task(
        id: '', // Supabase will generate
        userId: widget.user.id,
        date: _selectedDate,
        title: title,
        description: description.isEmpty ? null : description,
        isCompleted: false,
        createdAt: DateTime.now(),
        startTime: _startTime,
        endTime: _endTime,
      );

      await _supabaseService.createTask(task);
      _taskTitleController.clear();
      _taskDescriptionController.clear();
      setState(() {
        _startTime = null;
        _endTime = null;
      });
      await _loadTasks();
    } catch (e) {
      debugPrint('Error creating task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      final isCompleted = !task.isCompleted;
      await _supabaseService.updateTaskStatus(
        task.id,
        isCompleted,
        actualEndTime: isCompleted ? TimeOfDay.now() : null,
      );
      await _loadTasks();
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await _supabaseService.deleteTask(task.id);
      await _loadTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _updateMonthlyTaskStatus(String taskId, String status) async {
    try {
      await _supabaseService.updateMonthlyTaskStatus(
        taskId: taskId,
        userId: widget.user.id,
        status: status,
      );
      await _loadTasks();
    } catch (e) {
      debugPrint('Error updating monthly task status: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'On Hold':
        return Colors.orange;
      case 'Review':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red[900]!;
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange; // Medium
    }
  }

  double? _calculateDuration(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return null;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    int diffMinutes = endMinutes - startMinutes;
    if (diffMinutes < 0) {
      diffMinutes += 24 * 60; // Add 24 hours
    }
    return diffMinutes / 60.0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    'TASKS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Plan your work day by day',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date selector
            NeoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Date',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E, MMM d, yyyy').format(_selectedDate),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      'CHANGE',
                      style: GoogleFonts.spaceMono(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Monthly Tasks Section
            if (_monthlyTasks.isNotEmpty) ...[
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'MONTHLY TASKS',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._monthlyTasks.map((task) {
                      // Get completion status
                      final userTaskData = task['user_monthly_tasks'];
                      String status = 'Pending';
                      if (userTaskData != null &&
                          userTaskData.isNotEmpty &&
                          userTaskData[0]['status'] != null) {
                        status = userTaskData[0]['status'];
                      }
                      final isCompleted = status == 'Completed';
                      final priority = task['priority'] ?? 'Medium';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black
                              : (isCompleted
                                  ? Colors.green[50]
                                  : Colors.grey[100]),
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: 'Change Status',
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _getStatusColor(status)),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.spaceMono(
                                    color: _getStatusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onSelected: (val) =>
                                  _updateMonthlyTaskStatus(task['id'], val),
                              itemBuilder: (context) => [
                                'Pending',
                                'In Progress',
                                'Completed',
                                'On Hold',
                                'Review'
                              ]
                                  .map((s) => PopupMenuItem(
                                      value: s,
                                      child: Text(s,
                                          style: GoogleFonts.spaceMono())))
                                  .toList(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(priority),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                        child: Text(
                                          priority.toUpperCase(),
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 8,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          task['title'],
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            decoration: isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (task['description'] != null &&
                                      task['description']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task['description'],
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Daily Tasks Section forselected date
            if (_dailyTasks.isNotEmpty) ...[
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TODAY\'S ASSIGNED TASKS',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._dailyTasks.map((task) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black
                              : (task.isCompleted
                                  ? Colors.green[50]
                                  : Colors.grey[100]),
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PopupMenuButton<String>(
                                  tooltip: 'Change Status',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(task.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: _getStatusColor(task.status)),
                                    ),
                                    child: Text(
                                      task.status,
                                      style: GoogleFonts.spaceMono(
                                        color: _getStatusColor(task.status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onSelected: (val) =>
                                      _updateMonthlyTaskStatus(task.id, val),
                                  itemBuilder: (context) => [
                                    'Pending',
                                    'In Progress',
                                    'Completed',
                                    'On Hold',
                                    'Review'
                                  ]
                                      .map((s) => PopupMenuItem(
                                          value: s,
                                          child: Text(s,
                                              style: GoogleFonts.spaceMono())))
                                      .toList(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                  task.priority),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                            child: Text(
                                              task.priority.toUpperCase(),
                                              style: GoogleFonts.spaceMono(
                                                fontSize: 8,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              style: GoogleFonts.spaceMono(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (task.description != null &&
                                          task.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.description!,
                                          style: GoogleFonts.spaceMono(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Progress bar (if time limit exists)
                            if (task.timeLimitHours != null) ...[
                              const SizedBox(height: 12),
                              LiquidProgressBar(
                                progress: task.progressPercentage,
                                timeRemaining: task.timeRemainingText,
                                isOverdue: task.isOverdue,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Add task form
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.playlist_add_check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ADD TASK',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskTitleController,
                    style: GoogleFonts.spaceMono(),
                    decoration: InputDecoration(
                      labelText: 'Task title',
                      labelStyle: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taskDescriptionController,
                    style: GoogleFonts.spaceMono(),
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickStartTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Time',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startTime == null
                                      ? 'Not set'
                                      : _startTime!.format(context),
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickEndTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.white : Colors.black,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Time',
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endTime == null
                                      ? 'Not set'
                                      : _endTime!.format(context),
                                  style: GoogleFonts.spaceMono(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_startTime != null && _endTime != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${_calculateDuration(_startTime, _endTime)!.toStringAsFixed(1)} hours',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: AppColors.brand,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addTask,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.add, size: 18),
                      label: Text(
                        _isLoading ? 'SAVING...' : 'ADD TASK',
                        style: GoogleFonts.spaceMono(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Task list
            NeoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.list_alt, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'TASKS FOR THE DAY',
                        style: GoogleFonts.spaceMono(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading && _tasks.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_tasks.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'NO TASKS FOR THIS DAY',
                          style: GoogleFonts.spaceMono(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._tasks.map((task) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black
                              : (task.isCompleted
                                  ? Colors.green[50]
                                  : Colors.grey[100]),
                          border: Border.all(
                            color: isDark ? Colors.white : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (_) => _toggleTask(task),
                              activeColor: AppColors.brand,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  if (task.description != null &&
                                      task.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      task.description!,
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  if (task.startTime != null ||
                                      task.endTime != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (task.startTime != null) ...[
                                          Icon(Icons.access_time,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${task.startTime!.format(context)}',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                        if (task.startTime != null &&
                                            task.endTime != null)
                                          Text(
                                            ' - ',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        if (task.endTime != null) ...[
                                          Text(
                                            '${task.endTime!.format(context)}',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                        if (task.durationInHours != null) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${task.durationInHours!.toStringAsFixed(1)}h)',
                                            style: GoogleFonts.spaceMono(
                                              fontSize: 10,
                                              color: AppColors.brand,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _deleteTask(task),
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              tooltip: 'Delete task',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

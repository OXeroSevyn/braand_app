import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';

class AdminMonthlyTasksScreen extends StatefulWidget {
  const AdminMonthlyTasksScreen({super.key});

  @override
  State<AdminMonthlyTasksScreen> createState() =>
      _AdminMonthlyTasksScreenState();
}

class _AdminMonthlyTasksScreenState extends State<AdminMonthlyTasksScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeLimitController = TextEditingController();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _employees = [];
  String _taskType = 'monthly'; // 'monthly' or 'daily'
  String? _selectedEmployeeId; // null = all employees
  String _timeUnit = 'hours'; // 'minutes', 'hours', 'days'
  bool _isPrivate = false;
  String _priority = 'Medium'; // Low, Medium, High, Urgent

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadEmployees();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _supabaseService.getMonthlyTasks(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      debugPrint('Error loading monthly tasks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _supabaseService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
    }
  }

  Future<void> _addTask() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_taskType == 'monthly') {
        await _supabaseService.createMonthlyTask(
          title: title,
          description: description.isEmpty ? null : description,
          month: _selectedMonth,
          year: _selectedYear,
          assignedTo: _selectedEmployeeId,
          isPrivate: _isPrivate,
          priority: _priority,
        );
      } else {
        // Daily task
        int? timeLimitValue;
        if (_timeLimitController.text.trim().isNotEmpty) {
          timeLimitValue = int.tryParse(_timeLimitController.text.trim());
          if (timeLimitValue == null || timeLimitValue <= 0) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please enter a valid time limit')),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        await _supabaseService.createDailyTask(
          title: title,
          description: description.isEmpty ? null : description,
          specificDate: _selectedDate,
          timeLimitValue: timeLimitValue,
          timeUnit: timeLimitValue != null ? _timeUnit : null,
          assignedTo: _selectedEmployeeId,
          isPrivate: _isPrivate,
          priority: _priority,
        );
      }

      _titleController.clear();
      _descriptionController.clear();
      _timeLimitController.clear();
      setState(() {
        _selectedEmployeeId = null;
        _isPrivate = false;
      });
      await _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_taskType == 'monthly' ? 'Monthly' : 'Daily'} task added!',
                style: GoogleFonts.spaceMono()),
            backgroundColor: AppColors.brand,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _supabaseService.deleteMonthlyTask(taskId);
      await _loadTasks();
    } catch (e) {
      debugPrint('Error deleting monthly task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MONTHLY TASKS',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month/Year selector
              NeoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Month',
                            style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getMonthName(_selectedMonth)} $_selectedYear',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 1) {
                                _selectedMonth = 12;
                                _selectedYear--;
                              } else {
                                _selectedMonth--;
                              }
                            });
                            _loadTasks();
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedMonth == 12) {
                                _selectedMonth = 1;
                                _selectedYear++;
                              } else {
                                _selectedMonth++;
                              }
                            });
                            _loadTasks();
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Add task form
              NeoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_task, size: 20),
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

                    // Task type selector
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Monthly',
                              style: GoogleFonts.spaceMono(fontSize: 12),
                            ),
                            value: 'monthly',
                            groupValue: _taskType,
                            onChanged: (value) {
                              setState(() => _taskType = value!);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.brand,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Date-Specific',
                              style: GoogleFonts.spaceMono(fontSize: 12),
                            ),
                            value: 'daily',
                            groupValue: _taskType,
                            onChanged: (value) {
                              setState(() => _taskType = value!);
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.brand,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Conditional date/month-year selector
                    if (_taskType == 'daily')
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: GoogleFonts.spaceMono(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_taskType == 'daily') const SizedBox(height: 12),

                    // Time limit (for daily tasks only)
                    if (_taskType == 'daily')
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _timeLimitController,
                              style: GoogleFonts.spaceMono(),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Time Limit - Optional',
                                labelStyle: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                hintText: 'e.g. 24',
                                hintStyle: GoogleFonts.spaceMono(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _timeUnit,
                              items: const [
                                DropdownMenuItem(
                                    value: 'minutes', child: Text('Minutes')),
                                DropdownMenuItem(
                                    value: 'hours', child: Text('Hours')),
                                DropdownMenuItem(
                                    value: 'days', child: Text('Days')),
                              ],
                              onChanged: (value) {
                                setState(() => _timeUnit = value!);
                              },
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                labelStyle: GoogleFonts.spaceMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: GoogleFonts.spaceMono(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                    if (_taskType == 'daily') const SizedBox(height: 12),

                    TextField(
                      controller: _titleController,
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
                      controller: _descriptionController,
                      style: GoogleFonts.spaceMono(),
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Employee assignment selector
                    DropdownButtonFormField<String?>(
                      value: _selectedEmployeeId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Employees'),
                        ),
                        ..._employees.map((employee) {
                          return DropdownMenuItem<String?>(
                            value: employee['id'] as String?,
                            child: Text(employee['name'] ?? 'Unknown'),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedEmployeeId = value);
                      },
                      decoration: InputDecoration(
                        labelText: 'Assign To',
                        labelStyle: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      style: GoogleFonts.spaceMono(fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    // Private task checkbox
                    CheckboxListTile(
                      value: _isPrivate,
                      onChanged: (value) {
                        setState(() => _isPrivate = value ?? false);
                      },
                      title: Text(
                        'Private Task (Admin Only)',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Only visible to admins in reports',
                        style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.brand,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
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
                          'TASKS FOR ${_getMonthName(_selectedMonth).toUpperCase()}',
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
                            'NO TASKS FOR THIS MONTH',
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
                            color: isDark ? Colors.black : Colors.grey[100],
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task['title'],
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (task['description'] != null &&
                                        task['description'].isNotEmpty) ...[
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
                              IconButton(
                                onPressed: () => _deleteTask(task['id']),
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
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}

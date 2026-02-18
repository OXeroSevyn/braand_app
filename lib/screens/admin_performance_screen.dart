import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../widgets/neo_card.dart';

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  // State
  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoadingEmployees = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final employees = await _supabaseService.getEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          if (employees.isNotEmpty) {
            _selectedEmployeeId = employees[0]['id'];
          }
          _isLoadingEmployees = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
      if (mounted) {
        setState(() => _isLoadingEmployees = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PERFORMANCE DASHBOARD',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Controls Section
                  NeoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FILTERS',
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Employee Selector
                        DropdownButtonFormField<String?>(
                          value: _selectedEmployeeId,
                          decoration: InputDecoration(
                            labelText: 'Select Employee',
                            labelStyle: GoogleFonts.spaceMono(fontSize: 12),
                            border: OutlineInputBorder(),
                            helperText: 'Showing metrics for selected employee',
                            helperStyle: GoogleFonts.spaceMono(fontSize: 10),
                          ),
                          items: _employees.map((e) {
                            return DropdownMenuItem<String?>(
                              value: e['id'] as String?,
                              child: Text(
                                e['name'] ?? 'Unknown',
                                style: GoogleFonts.spaceMono(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedEmployeeId = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date Selector Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: () {
                                        setState(() {
                                          if (_selectedMonth == 1) {
                                            _selectedMonth = 12;
                                            _selectedYear--;
                                          } else {
                                            _selectedMonth--;
                                          }
                                        });
                                      },
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _getMonthName(_selectedMonth),
                                          style: GoogleFonts.spaceMono(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '$_selectedYear',
                                          style: GoogleFonts.spaceMono(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: () {
                                        setState(() {
                                          if (_selectedMonth == 12) {
                                            _selectedMonth = 1;
                                            _selectedYear++;
                                          } else {
                                            _selectedMonth++;
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content Area
                  if (_selectedEmployeeId != null)
                    FutureBuilder<Map<String, dynamic>>(
                      future: _supabaseService.getEmployeePerformanceMetrics(
                        userId: _selectedEmployeeId!,
                        month: _selectedMonth,
                        year: _selectedYear,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading metrics: ${snapshot.error}',
                              style: GoogleFonts.spaceMono(color: Colors.red),
                            ),
                          );
                        }

                        final data = snapshot.data!;
                        final tasks = data['tasks'] as Map<String, dynamic>;
                        final attendance =
                            data['attendance'] as Map<String, dynamic>;
                        final leaves = data['leaves'] as Map<String, dynamic>;

                        return Column(
                          children: [
                            // KPI Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKPICard(
                                    title: 'Task Rate',
                                    value:
                                        '${(tasks['rate'] as double).toStringAsFixed(0)}%',
                                    subtitle:
                                        '${tasks['completed']}/${tasks['total']} Done',
                                    icon: Icons.task_alt,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildKPICard(
                                    title: 'Punctuality',
                                    value:
                                        '${(attendance['punctuality'] as double).toStringAsFixed(0)}%',
                                    subtitle: '${attendance['late']} Late',
                                    icon: Icons.access_time,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildKPICard(
                                    title: 'Attendance',
                                    value: '${attendance['present']} Days',
                                    subtitle: 'Present',
                                    icon: Icons.calendar_today,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildKPICard(
                                    title: 'Leaves',
                                    value: '${leaves['total']} Days',
                                    subtitle: 'Approved',
                                    icon: Icons.flight_takeoff,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Activity Breakdown Chart
                            NeoCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ACTIVITY BREAKDOWN',
                                    style: GoogleFonts.spaceMono(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 200,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: PieChart(
                                            PieChartData(
                                              sectionsSpace: 0,
                                              centerSpaceRadius: 40,
                                              sections: [
                                                PieChartSectionData(
                                                  color: Colors.green,
                                                  value: (attendance['present']
                                                          as int)
                                                      .toDouble(),
                                                  title:
                                                      '${attendance['present']}',
                                                  radius: 50,
                                                  titleStyle:
                                                      GoogleFonts.spaceMono(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.purple,
                                                  value:
                                                      (leaves['total'] as int)
                                                          .toDouble(),
                                                  title: '${leaves['total']}',
                                                  radius: 50,
                                                  titleStyle:
                                                      GoogleFonts.spaceMono(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                PieChartSectionData(
                                                  color: Colors.blue,
                                                  value: (tasks['completed']
                                                          as int)
                                                      .toDouble(),
                                                  title:
                                                      '${tasks['completed']}',
                                                  radius: 50,
                                                  titleStyle:
                                                      GoogleFonts.spaceMono(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildLegendItem(
                                                Colors.green, 'Present Days'),
                                            const SizedBox(height: 8),
                                            _buildLegendItem(
                                                Colors.purple, 'Leave Days'),
                                            const SizedBox(height: 8),
                                            _buildLegendItem(
                                                Colors.blue, 'Tasks Completed'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return NeoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                title,
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceMono(fontSize: 12),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/report_service.dart';
import '../models/report_data.dart';

class ReportsScreen extends StatefulWidget {
  final bool isEmbedded;
  const ReportsScreen({super.key, this.isEmbedded = false});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<ReportData> _reportData = [];
  Timer? _refreshTimer;
  bool _isFetching = false;

  final SupabaseService _supabaseService = SupabaseService();
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    _fetchReport();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        _fetchReport(isAutoRefresh: true);
      }
    });
  }

  Future<void> _fetchReport({bool isAutoRefresh = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (!isAutoRefresh && _reportData.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final data =
          await _supabaseService.getAttendanceReport(_startDate, _endDate);
      if (mounted) {
        setState(() {
          _reportData = data;
        });
      }
    } catch (e) {
      if (mounted && !isAutoRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching report: $e')),
        );
      }
    } finally {
      _isFetching = false;
      if (mounted && !isAutoRefresh) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return Column(
        children: [
          // Embedded Header with Date Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selectDateRange,
                  tooltip: 'Select Date Range',
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSummaryCard(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      await _fetchReport(isAutoRefresh: true),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _reportData.length,
                    itemBuilder: (context, index) {
                      final report = _reportData[index];
                      return ExpansionTile(
                        leading: CircleAvatar(
                          child: Text(report.user.name[0]),
                        ),
                        title: Text(report.user.name),
                        subtitle: Text(
                            'Days: ${report.totalDaysPresent} | Time: ${_formatDuration(report.totalHoursWorked)}'),
                        children: report.dailyHours.entries.map((entry) {
                          return ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            title: Text(entry.key), // Date
                            trailing:
                                Text(_formatDuration(entry.value)), // Duration
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export Excel'),
                        onPressed: () => _reportService.generateAndShareExcel(
                            _reportData, _startDate, _endDate),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        onPressed: () => _reportService.generateAndSharePdf(
                            _reportData, _startDate, _endDate),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildSummaryCard() {
    int totalDays = 0;
    Duration totalHours = Duration.zero;
    for (var r in _reportData) {
      totalDays += r.totalDaysPresent;
      totalHours += r.totalHoursWorked;
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Employees', '${_reportData.length}'),
            _buildStatItem('Total Man-Days', '$totalDays'),
            _buildStatItem('Total Time', _formatDuration(totalHours)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s ${d.inMilliseconds % 1000}ms';
  }
}

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/report_data.dart';
import '../models/task_report_data.dart';

class ReportService {
  Future<void> generateAndShareExcel(
      List<ReportData> data, DateTime start, DateTime end) async {
    var excel = Excel.createExcel();

    // Summary Sheet
    Sheet summarySheet = excel['Summary'];
    summarySheet.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Department'),
      TextCellValue('Total Days'),
      TextCellValue('Total Work Hours'),
    ]);

    for (var report in data) {
      final hours = report.totalHoursWorked.inHours;
      final minutes = report.totalHoursWorked.inMinutes % 60;
      final seconds = report.totalHoursWorked.inSeconds % 60;
      final millis = report.totalHoursWorked.inMilliseconds % 1000;
      summarySheet.appendRow([
        TextCellValue(report.user.name),
        TextCellValue(report.user.department),
        TextCellValue(report.totalDaysPresent.toString()),
        TextCellValue('${hours}h ${minutes}m ${seconds}s ${millis}ms'),
      ]);
    }

    // Add grand total
    final totalHours = data.fold<Duration>(
      Duration.zero,
      (sum, report) => sum + report.totalHoursWorked,
    );
    final grandTotalHours = totalHours.inHours;
    final grandTotalMinutes = totalHours.inMinutes % 60;
    final grandTotalSeconds = totalHours.inSeconds % 60;
    final grandTotalMillis = totalHours.inMilliseconds % 1000;

    summarySheet.appendRow([]);
    summarySheet.appendRow([
      TextCellValue('GRAND TOTAL'),
      TextCellValue(''),
      TextCellValue(
          data.fold<int>(0, (sum, r) => sum + r.totalDaysPresent).toString()),
      TextCellValue(
          '${grandTotalHours}h ${grandTotalMinutes}m ${grandTotalSeconds}s ${grandTotalMillis}ms'),
    ]);

    // Detailed Records Sheet
    Sheet detailsSheet = excel['Detailed Records'];
    detailsSheet.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Department'),
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Time'),
      TextCellValue('Location'),
    ]);

    for (var report in data) {
      for (var record in report.records) {
        final date = DateTime.fromMillisecondsSinceEpoch(record.timestamp);
        detailsSheet.appendRow([
          TextCellValue(report.user.name),
          TextCellValue(report.user.department),
          TextCellValue(DateFormat('yyyy-MM-dd').format(date)),
          TextCellValue(record.type.toString().split('.').last),
          TextCellValue(DateFormat('HH:mm:ss').format(date)),
          TextCellValue(record.location != null
              ? '${record.location!.lat}, ${record.location!.lng}'
              : 'N/A'),
        ]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await _saveAndShareFile(
          'attendance_report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.xlsx',
          fileBytes);
    }
  }

  /// Generate Excel for task reports (per employee, per task)
  Future<void> generateAndShareTaskExcel(
      List<TaskReportData> data, DateTime start, DateTime end) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Task Report'];

    // Headers
    sheetObject.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Department'),
      TextCellValue('Task Date'),
      TextCellValue('Title'),
      TextCellValue('Description'),
      TextCellValue('Start Time'),
      TextCellValue('End Time'),
      TextCellValue('Duration (Actual)'),
      TextCellValue('Status'),
    ]);

    for (var report in data) {
      for (var task in report.tasks) {
        String formatTime(TimeOfDay? time) {
          if (time == null) return '';
          return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        }

        String durationText;
        if (task.isCompleted && task.durationInHours != null) {
          durationText = '${task.durationInHours!.toStringAsFixed(2)} hrs';
        } else if (task.isCompleted) {
          durationText = 'Completed (Time N/A)';
        } else {
          durationText = 'Ongoing';
        }

        // Use actual end time if available, otherwise estimated
        String endTimeText = '';
        if (task.actualEndTime != null) {
          endTimeText = formatTime(task.actualEndTime);
        } else {
          endTimeText = formatTime(task.endTime);
        }

        sheetObject.appendRow([
          TextCellValue(report.user.name),
          TextCellValue(report.user.department),
          TextCellValue(DateFormat('yyyy-MM-dd').format(task.date)),
          TextCellValue(task.title),
          TextCellValue(task.description ?? ''),
          TextCellValue(formatTime(task.startTime)),
          TextCellValue(endTimeText),
          TextCellValue(durationText),
          TextCellValue(task.isCompleted ? 'Completed' : 'Ongoing'),
        ]);
      }
    }

    // Add summary row
    sheetObject.appendRow([]);
    sheetObject.appendRow([
      TextCellValue('SUMMARY'),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('Total Hours:'),
      TextCellValue(data
          .fold<double>(0.0, (sum, report) => sum + report.totalHours)
          .toStringAsFixed(2)),
      TextCellValue(''),
    ]);

    final fileBytes = excel.save();
    if (fileBytes != null) {
      await _saveAndShareFile(
        'task_report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.xlsx',
        fileBytes,
      );
    }
  }

  /// Generate PDF for task reports
  Future<void> generateAndShareTaskPdf(
      List<TaskReportData> data, DateTime start, DateTime end) async {
    final pdf = pw.Document();

    String formatTime(TimeOfDay? time) {
      if (time == null) return '';
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Task Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Paragraph(
              text:
                  'Period: ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}',
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Tasks: ${data.fold<int>(0, (sum, report) => sum + report.totalTasks)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Total Hours: ${data.fold<double>(0.0, (sum, report) => sum + report.totalHours).toStringAsFixed(1)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headers: [
                'Name',
                'Date',
                'Title',
                'Start',
                'End',
                'Duration',
                'Status'
              ],
              data: data.expand((report) {
                return report.tasks.map((task) {
                  String durationText;
                  if (task.isCompleted && task.durationInHours != null) {
                    durationText =
                        '${task.durationInHours!.toStringAsFixed(1)}h';
                  } else if (task.isCompleted) {
                    durationText = 'N/A';
                  } else {
                    durationText = 'Ongoing';
                  }

                  String endTimeText = '';
                  if (task.actualEndTime != null) {
                    endTimeText = formatTime(task.actualEndTime);
                  } else {
                    endTimeText = formatTime(task.endTime);
                  }

                  return [
                    report.user.name,
                    DateFormat('MM-dd').format(task.date),
                    task.title,
                    formatTime(task.startTime),
                    endTimeText,
                    durationText,
                    task.isCompleted ? 'Done' : 'In Prog',
                  ];
                });
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Hours by Employee',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...data.map((report) {
              if (report.totalHours == 0) return pw.SizedBox();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(report.user.name),
                    pw.Text(
                      '${report.totalHours.toStringAsFixed(1)}h',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    final fileBytes = await pdf.save();
    await _saveAndShareFile(
      'task_report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.pdf',
      fileBytes,
    );
  }

  Future<void> generateAndSharePdf(
      List<ReportData> data, DateTime start, DateTime end) async {
    final pdf = pw.Document();

    // Calculate totals
    final totalHours = data.fold<Duration>(
      Duration.zero,
      (sum, report) => sum + report.totalHoursWorked,
    );
    final totalDays = data.fold<int>(0, (sum, r) => sum + r.totalDaysPresent);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Attendance Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Paragraph(
              text:
                  'Period: ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}',
            ),
            pw.SizedBox(height: 10),

            // Summary Statistics
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Text(
                  'Employees: ${data.length}',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Days: $totalDays',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Total Work Hours: ${totalHours.inHours}h ${totalHours.inMinutes % 60}m ${totalHours.inSeconds % 60}s ${totalHours.inMilliseconds % 1000}ms',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary Table
            pw.Text(
              'Summary by Employee',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Employee', 'Department', 'Days', 'Work Hours'],
              data: data.map((report) {
                final hours = report.totalHoursWorked.inHours;
                final minutes = report.totalHoursWorked.inMinutes % 60;
                final seconds = report.totalHoursWorked.inSeconds % 60;
                final millis = report.totalHoursWorked.inMilliseconds % 1000;
                return [
                  report.user.name,
                  report.user.department,
                  report.totalDaysPresent.toString(),
                  '${hours}h ${minutes}m ${seconds}s ${millis}ms',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 30),

            // Detailed Records
            pw.Text(
              'Detailed Records',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              context: context,
              headers: ['Name', 'Date', 'Type', 'Time'],
              data: data.expand((report) {
                return report.records.map((record) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(record.timestamp);
                  return [
                    report.user.name,
                    DateFormat('yyyy-MM-dd').format(date),
                    record.type.toString().split('.').last,
                    DateFormat('HH:mm').format(date),
                  ];
                });
              }).toList(),
            ),
          ];
        },
      ),
    );

    final fileBytes = await pdf.save();
    await _saveAndShareFile(
        'attendance_report_${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}.pdf',
        fileBytes);
  }

  Future<void> _saveAndShareFile(String fileName, List<int> bytes) async {
    try {
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: fileName.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Here is the attendance report.',
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}

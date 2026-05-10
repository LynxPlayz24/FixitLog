import 'dart:io';
import 'package:csv/csv.dart';
import 'package:fixitlog/models/item.dart';
import 'package:fixitlog/models/task_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  ReportService._();
  static final instance = ReportService._();

  /// Generates a CSV file for the item's maintenance history and returns its absolute path.
  Future<String> generateCsvReport(Item item) async {
    final List<List<dynamic>> rows = [];
    
    // Header
    rows.add(['Item Name', 'Task', 'Date Completed', 'Notes']);
    
    // Sort all logs chronologically (newest first)
    final allLogs = _getAllLogsSorted(item);
    
    for (var logEntry in allLogs) {
      final taskName = logEntry['taskName'] as String;
      final log = logEntry['log'] as TaskLog;
      
      rows.add([
        item.name,
        taskName,
        _formatDate(log.completedDate),
        log.note,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${item.name.replaceAll(' ', '_')}_maintenance_report.csv';
    final file = File(path);
    await file.writeAsString(csvString);
    
    return path;
  }

  /// Generates a PDF file for the item's maintenance history and returns its absolute path.
  Future<String> generatePdfReport(Item item) async {
    final pdf = pw.Document();
    
    final allLogs = _getAllLogsSorted(item);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Maintenance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatDate(DateTime.now()), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Item Info
            pw.Text('Item: ${item.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Category: ${item.itemType.label}', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            
            // History Table
            if (allLogs.isEmpty)
              pw.Text('No maintenance history logged yet.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Date', 'Task', 'Notes'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                data: allLogs.map((entry) {
                  final taskName = entry['taskName'] as String;
                  final log = entry['log'] as TaskLog;
                  return [
                    _formatDate(log.completedDate),
                    taskName,
                    log.note,
                  ];
                }).toList(),
              ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${item.name.replaceAll(' ', '_')}_maintenance_report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  List<Map<String, dynamic>> _getAllLogsSorted(Item item) {
    final allLogs = <Map<String, dynamic>>[];
    for (var task in item.tasks) {
      for (var log in task.history) {
        allLogs.add({
          'taskName': task.name,
          'log': log,
        });
      }
    }
    allLogs.sort((a, b) {
      final logA = a['log'] as TaskLog;
      final logB = b['log'] as TaskLog;
      return logB.completedDate.compareTo(logA.completedDate);
    });
    return allLogs;
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

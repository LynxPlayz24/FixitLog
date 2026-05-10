import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/item.dart';
import '../models/task_log.dart';
import '../services/report_service.dart';
import '../utils/notification_service.dart';

class ItemHistoryPage extends StatefulWidget {
  final Item item;

  const ItemHistoryPage({super.key, required this.item});

  @override
  State<ItemHistoryPage> createState() => _ItemHistoryPageState();
}

class _ItemHistoryPageState extends State<ItemHistoryPage> {
  late List<Map<String, dynamic>> _allLogs;

  @override
  void initState() {
    super.initState();
    _allLogs = _getAllLogsSorted(widget.item);
  }

  List<Map<String, dynamic>> _getAllLogsSorted(Item item) {
    final logs = <Map<String, dynamic>>[];
    for (var task in item.tasks) {
      for (var log in task.history) {
        logs.add({
          'taskName': task.name,
          'log': log,
        });
      }
    }
    logs.sort((a, b) {
      final logA = a['log'] as TaskLog;
      final logB = b['log'] as TaskLog;
      return logB.completedDate.compareTo(logA.completedDate);
    });
    return logs;
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _exportCsv() async {
    try {
      final path = await ReportService.instance.generateCsvReport(widget.item);
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], subject: '${widget.item.name} Maintenance Report');
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.showError(context, 'Failed to export CSV: $e');
    }
  }

  Future<void> _exportPdf() async {
    try {
      final path = await ReportService.instance.generatePdfReport(widget.item);
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], subject: '${widget.item.name} Maintenance Report');
    } catch (e) {
      if (!mounted) return;
      NotificationService.instance.showError(context, 'Failed to export PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.item.name} History'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'csv') _exportCsv();
              if (value == 'pdf') _exportPdf();
            },
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export Report',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _allLogs.isEmpty
          ? const Center(
              child: Text(
                'No maintenance history logged yet.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _allLogs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = _allLogs[i];
                final log = item['log'] as TaskLog;
                final taskName = item['taskName'] as String;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(
                    taskName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_formatDate(log.completedDate)),
                        ],
                      ),
                      if (log.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.note,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

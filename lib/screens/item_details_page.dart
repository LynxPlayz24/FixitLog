import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../models/task.dart';
import '../services/local_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'edit_item_screen.dart';

class ItemDetailsPage extends StatefulWidget {
  final Item item;
  const ItemDetailsPage({super.key, required this.item});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  final _imagePicker = ImagePicker();

  // ── Add task dialog ─────────────────────────────────────────────────

  void _addNewTask() {
    _showTaskDialog(
      title: 'Add Maintenance Task',
      actionLabel: 'Add',
      onSubmit: (task) {
        setState(() => widget.item.tasks.add(task));
        LocalNotificationService.instance.rescheduleAll();
      },
    );
  }

  // ── Edit task dialog ────────────────────────────────────────────────

  void _editTask(int index) {
    final existing = widget.item.tasks[index];
    _showTaskDialog(
      title: 'Edit Task',
      actionLabel: 'Save',
      initialName: existing.name,
      initialDate: existing.dateDone,
      initialReminderDays: existing.reminderDays,
      initialPhotoBase64: existing.photoBase64,
      initialNote: existing.note,
      onSubmit: (updatedTask) {
        setState(() {
          existing
            ..name = updatedTask.name
            ..dateDone = updatedTask.dateDone
            ..reminderDays = updatedTask.reminderDays
            ..photoBase64 = updatedTask.photoBase64
            ..note = updatedTask.note;
        });
        LocalNotificationService.instance.rescheduleAll();
      },
    );
  }

  // ── Shared task dialog ──────────────────────────────────────────────

  void _showTaskDialog({
    required String title,
    required String actionLabel,
    required void Function(Task task) onSubmit,
    String initialName = '',
    DateTime? initialDate,
    int initialReminderDays = 30,
    String? initialPhotoBase64,
    String initialNote = '',
  }) {
    final nameCtrl = TextEditingController(text: initialName);
    final reminderCtrl =
        TextEditingController(text: initialReminderDays.toString());
    final noteCtrl = TextEditingController(text: initialNote);
    DateTime selectedDate = initialDate ?? DateTime.now();
    Uint8List? photoBytes = initialPhotoBase64 != null &&
            initialPhotoBase64.isNotEmpty
        ? base64Decode(initialPhotoBase64)
        : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Task name
                    TextField(
                      controller: nameCtrl,
                      autofocus: initialName.isEmpty,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        hintText: 'e.g., Oil change',
                        prefixIcon: Icon(Icons.task_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date done
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date Done',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(_formatDate(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reminder interval
                    TextField(
                      controller: reminderCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Reminder Interval (days)',
                        hintText: 'e.g., 30',
                        prefixIcon: Icon(Icons.alarm_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Photo (optional)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 512,
                                maxHeight: 512,
                                imageQuality: 70,
                              );
                              if (picked != null) {
                                final bytes = await picked.readAsBytes();
                                setDialogState(() => photoBytes = bytes);
                              }
                            },
                            icon: const Icon(Icons.add_a_photo_outlined,
                                size: 18),
                            label: Text(photoBytes != null
                                ? 'Photo added ✓'
                                : 'Add Photo (optional)'),
                          ),
                        ),
                        if (photoBytes != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setDialogState(() => photoBytes = null),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(photoBytes!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(1),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Note (optional)
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Any additional details...',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final days = int.tryParse(reminderCtrl.text.trim()) ?? 30;

                    final task = Task.create(
                      name: name,
                      dateDone: selectedDate,
                      reminderDays: days,
                      photoBase64:
                          photoBytes != null ? base64Encode(photoBytes!) : null,
                      note: noteCtrl.text.trim(),
                    );
                    onSubmit(task);
                    Navigator.pop(ctx);
                  },
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteTask(int index) {
    setState(() {
      widget.item.tasks.removeAt(index);
    });
    LocalNotificationService.instance.rescheduleAll();
  }

  // ── Edit item ───────────────────────────────────────────────────────

  Future<void> _editItem() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: widget.item),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      widget.item.name = result['name'] as String;
      widget.item.itemType = result['itemType'] as ItemType;
      widget.item.imagesBase64
        ..clear()
        ..addAll((result['imagesBase64'] as List).cast<String>());
    });
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tasks = widget.item.tasks;
    final item = widget.item;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Item',
            onPressed: () => _editItem(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Item header with images ─────────────────────────────────
          if (item.imagesBase64.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: item.imagesBase64.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i < item.imagesBase64.length - 1 ? 8 : 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(item.imagesBase64[i]),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Item info bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.itemType.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Task list ──────────────────────────────────────────────
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No maintenance tasks yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskTile(
                        task: tasks[index],
                        onTap: () => _editTask(index),
                        onDelete: () => _deleteTask(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

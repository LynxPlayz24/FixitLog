import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

/// A reusable card widget that displays a [Task].
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;
  final VoidCallback? onHistory;

  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onComplete,
    this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = task.photoBase64 != null && task.photoBase64!.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo thumbnail (if exists)
              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(task.photoBase64!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                // Task icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (task.isOverdue
                            ? Colors.redAccent
                            : AppTheme.primaryPurple)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    color: task.isOverdue
                        ? Colors.redAccent
                        : AppTheme.primaryPurple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Date done + reminder
                    Text(
                      'Done: ${_formatDate(task.dateDone)}  •  Every ${task.reminderDays}d',
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    // Due status
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        task.isOverdue
                            ? 'Overdue by ${-task.daysUntilDue} days'
                            : 'Due in ${task.daysUntilDue} days',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: task.isOverdue
                              ? Colors.redAccent
                              : AppTheme.successGreen,
                        ),
                      ),
                    ),
                    // Note preview
                    if (task.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          task.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onHistory != null)
                    IconButton(
                      icon: Icon(Icons.history,
                          color: colorScheme.primary, size: 20),
                      tooltip: 'View History',
                      onPressed: onHistory,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  if (onComplete != null)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppTheme.successGreen, size: 20),
                      tooltip: 'Complete Task',
                      onPressed: onComplete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      tooltip: 'Delete Task',
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

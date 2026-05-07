import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

/// A reusable card widget that displays an [Item] summary.
class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalTasks = item.tasks.length;
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = item.imagesBase64.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail or icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasImage
                    ? Image.memory(
                        base64Decode(item.imagesBase64.first),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                        child: Icon(
                          _iconForType(item.itemType),
                          color: AppTheme.primaryPurple,
                        ),
                      ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.itemType.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (totalTasks > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$totalTasks task${totalTasks == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _iconForType(item.itemType),
                  size: 18,
                  color: AppTheme.primaryPurple,
                ),
              ),

              // Delete button
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: colorScheme.onSurfaceVariant, size: 20),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(ItemType type) {
    switch (type) {
      case ItemType.car:
        return Icons.directions_car;
      case ItemType.motorcycle:
        return Icons.two_wheeler;
      case ItemType.bicycle:
        return Icons.pedal_bike;
      case ItemType.electronics:
        return Icons.devices;
      case ItemType.appliance:
        return Icons.kitchen;
      case ItemType.home:
        return Icons.home;
      case ItemType.other:
        return Icons.build;
    }
  }
}

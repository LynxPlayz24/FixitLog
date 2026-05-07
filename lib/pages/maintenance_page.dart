import 'package:flutter/material.dart';
import '../models/item.dart';
import '../screens/add_item_screen.dart';
import '../screens/item_details_page.dart';
import '../services/local_notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/item_card.dart';
import '../utils/notification_service.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  List<Item> items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final loaded = await StorageService.instance.loadItems();
    if (mounted) {
      setState(() {
        items = loaded;
        _loading = false;
      });
    }
  }

  Future<void> _saveItems() async {
    await StorageService.instance.saveItems(items);
  }

  Future<void> _addItem() async {
    final newItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(builder: (context) => const AddItemScreen()),
    );

    if (newItem != null) {
      setState(() {
        items.add(newItem);
      });
      await _saveItems();
      await LocalNotificationService.instance.rescheduleAll();
      if (mounted) {
        NotificationService.instance
            .showSuccess(context, '${newItem.name} added!');
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final removed = items[index];
    setState(() {
      items.removeAt(index);
    });
    await _saveItems();
    await LocalNotificationService.instance.rescheduleAll();
    if (mounted) {
      NotificationService.instance
          .showInfo(context, '${removed.name} removed.');
    }
  }

  Future<void> _openItemDetails(int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsPage(item: items[index]),
      ),
    );

    // After returning, the item's task list may have changed — persist.
    await _saveItems();
    await LocalNotificationService.instance.rescheduleAll();
    setState(() {}); // Refresh cards to show updated task counts.
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No items yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: items[index],
                  onTap: () => _openItemDetails(index),
                  onDelete: () => _deleteItem(index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}

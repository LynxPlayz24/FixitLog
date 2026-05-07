import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

/// A dedicated screen for adding a new maintenance item.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();

  ItemType _selectedType = ItemType.car;
  final List<Uint8List> _images = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final imagesBase64 = _images.map((b) => base64Encode(b)).toList();

    final newItem = Item.create(
      name: name,
      itemType: _selectedType,
      imagesBase64: imagesBase64,
    );
    Navigator.pop(context, newItem);
  }

  Future<void> _addImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _images.add(bytes));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photos ──────────────────────────────────────────────
              Text(
                'Photos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add button
                    GestureDetector(
                      onTap: _addImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppTheme.primaryPurple),
                            SizedBox(height: 4),
                            Text('Add',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryPurple)),
                          ],
                        ),
                      ),
                    ),
                    // Existing images
                    ..._images.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                entry.value,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(entry.key),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Item name ───────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., My Toyota, Kitchen Fridge',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Item type ───────────────────────────────────────────
              Text(
                'Item Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ItemType.values.map((type) {
                  final selected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.label),
                    avatar: Icon(
                      _iconForType(type),
                      size: 18,
                      color: selected ? Colors.white : colorScheme.onSurfaceVariant,
                    ),
                    selected: selected,
                    selectedColor: AppTheme.primaryPurple,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : colorScheme.onSurface,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // ── Submit ──────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
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

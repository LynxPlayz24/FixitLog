import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item.dart';
import '../theme/app_theme.dart';

/// Screen for editing an existing item's name, type, and photos.
class EditItemScreen extends StatefulWidget {
  final Item item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _imagePicker = ImagePicker();

  late ItemType _selectedType;
  late List<Uint8List> _images;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _selectedType = widget.item.itemType;
    _images = widget.item.imagesBase64
        .map((b64) => base64Decode(b64))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Return a map of updated values
    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'itemType': _selectedType,
      'imagesBase64': _images.map((b) => base64Encode(b)).toList(),
    });
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
      appBar: AppBar(title: const Text('Edit Item')),
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
                    GestureDetector(
                      onTap: _addImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppTheme.primaryPurple.withValues(alpha: 0.3),
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
                      color: selected
                          ? Colors.white
                          : colorScheme.onSurfaceVariant,
                    ),
                    selected: selected,
                    selectedColor: AppTheme.primaryPurple,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : colorScheme.onSurface,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // ── Save ────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
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

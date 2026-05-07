import 'dart:convert';
import 'task.dart';

/// Predefined item types.
enum ItemType {
  car('Car', 'directions_car'),
  motorcycle('Motorcycle', 'two_wheeler'),
  bicycle('Bicycle', 'pedal_bike'),
  electronics('Electronics', 'devices'),
  appliance('Appliance', 'kitchen'),
  home('Home', 'home'),
  other('Other', 'build');

  final String label;
  final String iconName;
  const ItemType(this.label, this.iconName);

  static ItemType fromString(String value) {
    return ItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ItemType.other,
    );
  }
}

class Item {
  final String id;
  String name;
  ItemType itemType;
  final DateTime addedDate;
  final List<String> imagesBase64; // multiple photos
  final List<Task> tasks;

  Item({
    required this.id,
    required this.name,
    required this.itemType,
    required this.addedDate,
    List<String>? imagesBase64,
    List<Task>? tasks,
  })  : imagesBase64 = imagesBase64 ?? [],
        tasks = tasks ?? [];

  /// Create an Item with an auto-generated ID.
  factory Item.create({
    required String name,
    required ItemType itemType,
    List<String>? imagesBase64,
  }) {
    return Item(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      itemType: itemType,
      addedDate: DateTime.now(),
      imagesBase64: imagesBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemType': itemType.name,
      'addedDate': addedDate.toIso8601String(),
      'imagesBase64': imagesBase64,
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      itemType: json['itemType'] != null
          ? ItemType.fromString(json['itemType'] as String)
          : ItemType.other,
      addedDate: DateTime.parse(json['addedDate'] as String),
      imagesBase64: (json['imagesBase64'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String encode() => jsonEncode(toJson());

  factory Item.decode(String source) =>
      Item.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

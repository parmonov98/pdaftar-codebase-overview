import 'package:pdaftar_todo/src/domain/entities/todo_item.dart';

class TodoItemModel extends TodoItem {
  const TodoItemModel({
    required super.id,
    required super.title,
    super.isCompleted = false,
    super.position = 0,
    super.createdById,
    super.createdAt,
    super.updatedAt,
  });

  factory TodoItemModel.fromJson(Map<String, dynamic> json) {
    return TodoItemModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      isCompleted: (json['is_completed'] is bool)
          ? json['is_completed'] as bool
          : (json['is_completed'] == 1 || json['is_completed'] == 'true'),
      position: json['position'] as int? ?? 0,
      createdById: json['created_by_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'is_completed': isCompleted,
      'position': position,
      'created_by_id': createdById,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  TodoItem toEntity() {
    return TodoItem(
      id: id,
      title: title,
      isCompleted: isCompleted,
      position: position,
      createdById: createdById,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

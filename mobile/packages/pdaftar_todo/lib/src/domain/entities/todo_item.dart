import 'package:equatable/equatable.dart';

class TodoItem extends Equatable {
  final int id;
  final String title;
  final bool isCompleted;
  final int position;
  final int? createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TodoItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.position = 0,
    this.createdById,
    this.createdAt,
    this.updatedAt,
  });

  TodoItem copyWith({
    String? title,
    bool? isCompleted,
    int? position,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdById: createdById,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, isCompleted, position, createdById, createdAt, updatedAt];
}

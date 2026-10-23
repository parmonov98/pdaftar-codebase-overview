import 'package:equatable/equatable.dart';
import 'package:pdaftar_todo/src/domain/entities/todo_item.dart';

enum TodoStatus { initial, loading, loaded, error }

class TodoState extends Equatable {
  final TodoStatus status;
  final List<TodoItem> todos;
  final String? errorMessage;

  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
    this.errorMessage,
  });

  /// Returns incomplete todos sorted by position.
  List<TodoItem> get incompleteTodos =>
      todos.where((t) => !t.isCompleted).toList();

  /// Returns completed todos sorted by position.
  List<TodoItem> get completedTodos =>
      todos.where((t) => t.isCompleted).toList();

  TodoState copyWith({
    TodoStatus? status,
    List<TodoItem>? todos,
    String? errorMessage,
  }) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, todos, errorMessage];
}

import 'package:equatable/equatable.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodos extends TodoEvent {
  final bool isRefresh;
  const LoadTodos({this.isRefresh = false});
}

class CreateTodo extends TodoEvent {
  final String title;

  const CreateTodo({required this.title});

  @override
  List<Object?> get props => [title];
}

class UpdateTodo extends TodoEvent {
  final int id;
  final String? title;
  final int? position;

  const UpdateTodo({
    required this.id,
    this.title,
    this.position,
  });

  @override
  List<Object?> get props => [id, title, position];
}

class ToggleTodo extends TodoEvent {
  final int id;

  const ToggleTodo(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteTodo extends TodoEvent {
  final int id;

  const DeleteTodo(this.id);

  @override
  List<Object?> get props => [id];
}

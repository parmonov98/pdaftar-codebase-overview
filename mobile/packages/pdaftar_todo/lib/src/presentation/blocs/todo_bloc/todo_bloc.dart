import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdaftar_todo/pdaftar_todo.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final ITodoRepository _repository;
  final int shopId;

  TodoBloc({
    required ITodoRepository repository,
    required this.shopId,
  })  : _repository = repository,
        super(const TodoState()) {
    on<LoadTodos>(_onLoadTodos);
    on<CreateTodo>(_onCreateTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<DeleteTodo>(_onDeleteTodo);
  }

  Future<void> _onLoadTodos(
      LoadTodos event, Emitter<TodoState> emit) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: TodoStatus.loading));
    }

    try {
      final todos = await _repository.getTodos(shopId);
      emit(state.copyWith(
        status: TodoStatus.loaded,
        todos: todos,
      ));
      if (!event.isRefresh) {
        TodoPackage.trackEvent('Todo List Viewed', {
          'shop_id': shopId,
          'total_count': todos.length,
          'completed_count': todos.where((t) => t.isCompleted).length,
        });
      }
    } catch (e) {
      emit(state.copyWith(
        status: TodoStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreateTodo(
      CreateTodo event, Emitter<TodoState> emit) async {
    try {
      await _repository.createTodo(shopId, event.title);
      TodoPackage.trackEvent('Todo Created', {
        'shop_id': shopId,
        'title_length': event.title.length,
      });
      add(const LoadTodos(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateTodo(
      UpdateTodo event, Emitter<TodoState> emit) async {
    try {
      await _repository.updateTodo(
        shopId,
        event.id,
        title: event.title,
        position: event.position,
      );
      TodoPackage.trackEvent('Todo Edited', {
        'shop_id': shopId,
        'todo_id': event.id,
      });
      add(const LoadTodos(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onToggleTodo(
      ToggleTodo event, Emitter<TodoState> emit) async {
    try {
      // Optimistic update
      final targetTodo = state.todos.firstWhere((t) => t.id == event.id);
      final willBeCompleted = !targetTodo.isCompleted;

      final updatedTodos = state.todos.map((todo) {
        if (todo.id == event.id) {
          return todo.copyWith(isCompleted: willBeCompleted);
        }
        return todo;
      }).toList();
      emit(state.copyWith(todos: updatedTodos));

      await _repository.toggleTodo(shopId, event.id);
      TodoPackage.trackEvent(
        willBeCompleted ? 'Todo Completed' : 'Todo Uncompleted',
        {
          'shop_id': shopId,
          'todo_id': event.id,
          'title': targetTodo.title,
        },
      );
      add(const LoadTodos(isRefresh: true));
    } catch (e) {
      // Revert on error
      add(const LoadTodos(isRefresh: true));
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteTodo(
      DeleteTodo event, Emitter<TodoState> emit) async {
    try {
      // Optimistic update
      final updatedTodos =
          state.todos.where((todo) => todo.id != event.id).toList();
      emit(state.copyWith(todos: updatedTodos));

      await _repository.deleteTodo(shopId, event.id);
      TodoPackage.trackEvent('Todo Deleted', {
        'shop_id': shopId,
        'todo_id': event.id,
      });
      add(const LoadTodos(isRefresh: true));
    } catch (e) {
      // Revert on error
      add(const LoadTodos(isRefresh: true));
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }
}

import 'package:pdaftar_todo/src/domain/entities/todo_item.dart';

abstract class ITodoRepository {
  Future<List<TodoItem>> getTodos(int shopId);
  Future<TodoItem> createTodo(int shopId, String title);
  Future<TodoItem> updateTodo(int shopId, int id, {String? title, int? position});
  Future<TodoItem> toggleTodo(int shopId, int id);
  Future<void> deleteTodo(int shopId, int id);
}

import 'package:pdaftar_todo/src/domain/entities/todo_item.dart';
import 'package:pdaftar_todo/src/domain/repositories/i_todo_repository.dart';
import 'package:pdaftar_todo/src/data/datasources/todo_remote_data_source.dart';

class TodoRepositoryImpl implements ITodoRepository {
  final TodoRemoteDataSource _dataSource;

  TodoRepositoryImpl(this._dataSource);

  @override
  Future<List<TodoItem>> getTodos(int shopId) async {
    return await _dataSource.getTodos(shopId);
  }

  @override
  Future<TodoItem> createTodo(int shopId, String title) async {
    return await _dataSource.createTodo(shopId, title);
  }

  @override
  Future<TodoItem> updateTodo(int shopId, int id,
      {String? title, int? position}) async {
    return await _dataSource.updateTodo(shopId, id,
        title: title, position: position);
  }

  @override
  Future<TodoItem> toggleTodo(int shopId, int id) async {
    return await _dataSource.toggleTodo(shopId, id);
  }

  @override
  Future<void> deleteTodo(int shopId, int id) async {
    await _dataSource.deleteTodo(shopId, id);
  }
}

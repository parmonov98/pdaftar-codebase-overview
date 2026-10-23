import 'package:dio/dio.dart';
import 'package:pdaftar_todo/src/data/models/todo_item_model.dart';

abstract class TodoRemoteDataSource {
  Future<List<TodoItemModel>> getTodos(int shopId);
  Future<TodoItemModel> createTodo(int shopId, String title);
  Future<TodoItemModel> updateTodo(int shopId, int id,
      {String? title, int? position});
  Future<TodoItemModel> toggleTodo(int shopId, int id);
  Future<void> deleteTodo(int shopId, int id);
}

class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
  final Dio _dio;

  TodoRemoteDataSourceImpl(this._dio);

  String _basePath(int shopId) => '/api/mobile/shops/$shopId/todos';

  @override
  Future<List<TodoItemModel>> getTodos(int shopId) async {
    final response = await _dio.get(_basePath(shopId));
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => TodoItemModel.fromJson(e)).toList();
  }

  @override
  Future<TodoItemModel> createTodo(int shopId, String title) async {
    final response = await _dio.post(
      _basePath(shopId),
      data: {'title': title},
    );
    return TodoItemModel.fromJson(response.data['data']);
  }

  @override
  Future<TodoItemModel> updateTodo(int shopId, int id,
      {String? title, int? position}) async {
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (position != null) map['position'] = position;
    final response = await _dio.put(
      '${_basePath(shopId)}/$id',
      data: map,
    );
    return TodoItemModel.fromJson(response.data['data']);
  }

  @override
  Future<TodoItemModel> toggleTodo(int shopId, int id) async {
    final response = await _dio.patch(
      '${_basePath(shopId)}/$id/toggle',
    );
    return TodoItemModel.fromJson(response.data['data']);
  }

  @override
  Future<void> deleteTodo(int shopId, int id) async {
    await _dio.delete('${_basePath(shopId)}/$id');
  }
}

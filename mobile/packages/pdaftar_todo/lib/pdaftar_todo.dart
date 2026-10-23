library pdaftar_todo;

import 'package:dio/dio.dart';
import 'package:pdaftar_todo/src/data/datasources/todo_remote_data_source.dart';
import 'package:pdaftar_todo/src/data/repositories/todo_repository_impl.dart';
import 'package:pdaftar_todo/src/domain/repositories/i_todo_repository.dart';

export 'package:pdaftar_todo/src/domain/entities/todo_item.dart';
export 'package:pdaftar_todo/src/domain/repositories/i_todo_repository.dart';
export 'package:pdaftar_todo/src/data/models/todo_item_model.dart';
export 'package:pdaftar_todo/src/presentation/blocs/todo_bloc/todo_bloc.dart';
export 'package:pdaftar_todo/src/presentation/blocs/todo_bloc/todo_event.dart';
export 'package:pdaftar_todo/src/presentation/blocs/todo_bloc/todo_state.dart';
export 'package:pdaftar_todo/src/presentation/pages/todo_list_page.dart';
export 'package:pdaftar_todo/src/presentation/widgets/todo_item_widget.dart';
export 'package:pdaftar_todo/src/presentation/todo_router.dart';
export 'package:pdaftar_todo/src/presentation/todo_router.gm.dart';

/// Callback for analytics tracking from the todo module.
typedef TodoAnalyticsCallback = void Function(String event, [Map<String, dynamic>? props]);

/// Public Facade for the Todo Package
class TodoPackage {
  static late final ITodoRepository _repository;
  static late int Function() _shopIdProvider;
  static TodoAnalyticsCallback? _onAnalyticsEvent;

  static void init({
    required Dio dio,
    required int Function() shopIdProvider,
    TodoAnalyticsCallback? onAnalyticsEvent,
  }) {
    final remoteDataSource = TodoRemoteDataSourceImpl(dio);
    _repository = TodoRepositoryImpl(remoteDataSource);
    _shopIdProvider = shopIdProvider;
    _onAnalyticsEvent = onAnalyticsEvent;
  }

  static int get shopId => _shopIdProvider();

  /// Repository Access for BloC injection
  static ITodoRepository get repository => _repository;

  /// Track an analytics event (no-op if callback not set)
  static void trackEvent(String event, [Map<String, dynamic>? props]) {
    _onAnalyticsEvent?.call(event, props);
  }
}

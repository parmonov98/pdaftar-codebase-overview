import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdaftar_todo/pdaftar_todo.dart';

@RoutePage()
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final TodoBloc _bloc;

  static const _accentColor = Color(0xFF7C3AED);
  static const _headerGradient = [Color(0xFF1E1B4B), Color(0xFF312E81)];

  // App dark tokens (#649) — the package can't import the app's AppColors.
  // Light mode keeps every original constant.
  static const _darkPage = Color(0xFF15202B);
  static const _darkSurface = Color(0xFF202932);
  static const _accentOnDark = Color(0xFFB692F6);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _bloc = TodoBloc(
      repository: TodoPackage.repository,
      shopId: TodoPackage.shopId,
    )..add(const LoadTodos());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _bloc.close();
    super.dispose();
  }

  void _addTodo() {
    final title = _textController.text.trim();
    if (title.isEmpty) return;
    _bloc.add(CreateTodo(title: title));
    _textController.clear();
    _focusNode.requestFocus();
  }

  void _showItemMenu(TodoItem todo) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Tahrirlash'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditDialog(todo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title:
                  const Text("O'chirish", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _bloc.add(DeleteTodo(todo.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(TodoItem todo) {
    final editController = TextEditingController(text: todo.title);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tahrirlash'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Sarlavha'),
          onSubmitted: (_) {
            final newTitle = editController.text.trim();
            if (newTitle.isNotEmpty && newTitle != todo.title) {
              _bloc.add(UpdateTodo(id: todo.id, title: newTitle));
            }
            Navigator.of(dialogContext).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = editController.text.trim();
              if (newTitle.isNotEmpty && newTitle != todo.title) {
                _bloc.add(UpdateTodo(id: todo.id, title: newTitle));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text('Saqlash',
                style: TextStyle(
                    color: _isDark ? _accentOnDark : _accentColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? _darkPage : const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: _isDark ? Colors.white : Colors.black87),
          onPressed: () => context.router.parent()?.maybePop() ?? context.router.maybePop(),
        ),
        title: Text(
          'Todo',
          style: TextStyle(
            color: _isDark ? Colors.white : Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state.status == TodoStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == TodoStatus.error && state.todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Xatolik yuz berdi'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () =>
                        _bloc.add(const LoadTodos()),
                    child: const Text('Qayta urinish'),
                  ),
                ],
              ),
            );
          }

          final total = state.todos.length;
          final done = state.completedTodos.length;
          final incomplete = state.incompleteTodos;
          final completed = state.completedTodos;

          return Column(
            children: [
              // Header card
              _buildHeader(total, done),
              SizedBox(height: 12.h),

              // Todo list
              Expanded(
                child: total == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.checklist_rounded,
                                size: 64.sp, color: Colors.grey.shade300),
                            SizedBox(height: 12.h),
                            Text(
                              "Hozircha todo yo'q",
                              style: TextStyle(
                                  fontSize: 16.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<TodoBloc>()
                              .add(const LoadTodos(isRefresh: true));
                        },
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          children: [
                            ...incomplete.map((todo) => _buildTodoTile(todo)),
                            if (completed.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                    top: 16.h, bottom: 8.h, left: 4.w),
                                child: Text(
                                  'Bajarilgan (${completed.length})',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              ...completed
                                  .map((todo) => _buildTodoTile(todo)),
                            ],
                            SizedBox(height: 80.h),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      // Bottom input
      bottomSheet: _buildBottomInput(),
    );
  }

  Widget _buildHeader(int total, int done) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd.MM.yyyy').format(now);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _headerGradient.last.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vazifalar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 64.w,
            height: 64.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Center(
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$done/$total',
                        style: TextStyle(
                          color: _headerGradient.last,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoTile(TodoItem todo) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: _isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: todo.isCompleted
            ? Border.all(color: _accentColor.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) =>
            _bloc.add(DeleteTodo(todo.id)),
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
          leading: SizedBox(
            width: 24.w,
            height: 24.w,
            child: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) =>
                  _bloc.add(ToggleTodo(todo.id)),
              activeColor: _accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              fontSize: 15.sp,
              decoration: todo.isCompleted
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: todo.isCompleted
                  ? Colors.grey
                  : (_isDark ? Colors.white : Colors.black87),
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, size: 20.sp, color: Colors.grey),
            onPressed: () => _showItemMenu(todo),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 8.w,
        top: 12.h,
        bottom: MediaQuery.of(context).padding.bottom + 12.h,
      ),
      decoration: BoxDecoration(
        color: _isDark ? _darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Yangi todo qo'shish...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: _isDark ? _darkPage : const Color(0xFFF3F0FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addTodo(),
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white, size: 24.sp),
              onPressed: _addTodo,
            ),
          ),
        ],
      ),
    );
  }
}

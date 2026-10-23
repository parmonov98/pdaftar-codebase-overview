import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdaftar_todo/src/domain/entities/todo_item.dart';

class TodoItemWidget extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.w),
        color: Colors.red,
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: onToggle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    decoration: todo.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: todo.isCompleted
                        ? Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.5)
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:pdaftaruz/core/imports/imports.dart';

/// Grouped block of settings rows under a small uppercase header.
///
/// Replaces the patchwork of individually-styled `AppCardWidget`s on the
/// Profile screen — every group ends up looking, padding, and spacing the
/// same way regardless of how many items it has.
///
/// Children should be [SettingsRow]s; dividers between them are drawn
/// automatically (skip the last one).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.padding,
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i != children.length - 1) {
        separated.add(Divider(
          height: 1,
          thickness: 1,
          indent: 56.w,
          endIndent: 12.w,
          color: Theme.of(context).dividerColor,
        ));
      }
    }
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 8.h),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Theme.of(context).hintColor,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: separated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

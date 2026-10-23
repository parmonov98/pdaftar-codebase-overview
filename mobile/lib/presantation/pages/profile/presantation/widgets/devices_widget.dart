import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class DevicesWidget extends ConsumerWidget {
  const DevicesWidget({super.key});

  String _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'ios':
        return '📱';
      case 'android':
        return '🤖';
      case 'web':
        return '🌐';
      default:
        return '💻';
    }
  }

  String _getPlatformName(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'ios':
        return 'iOS';
      case 'android':
        return 'Android';
      case 'web':
        return 'Web';
      default:
        return platform ?? 'Unknown';
    }
  }

  String _formatLastUsed(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime.toLocal());
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${AppLocalization.getText(context)?.day ?? "kun"} oldin';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${AppLocalization.getText(context)?.hours ?? "soat"} oldin';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} daqiqa oldin';
    } else {
      return 'Hozir';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final sessions = state.sessionsData?.data ?? [];

    if (state.isLoadingSessions) {
      return Container(
        padding: EdgeInsets.all(16.sp),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sessions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.sp),
        child: Center(
          child: AppText(
            "Hech qanday qurilma topilmadi",
            fontSize: 14.sp,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      );
    }

    final otherDevices = sessions.where((s) => !(s.isCurrent ?? false)).toList();
    final hasOtherDevices = otherDevices.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Devices list
        for (final session in sessions)
          Builder(
            builder: (context) {
              final isCurrent = session.isCurrent ?? false;
              return Container(
            margin: EdgeInsets.only(bottom: 8.sp),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: isCurrent
                  ? Border.all(color: context.palette.accent, width: 1.5)
                  : null,
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
              leading: Container(
                width: 50.sp,
                height: 50.sp,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    _getPlatformIcon(session.platform),
                    style: TextStyle(fontSize: 24.sp),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: AppText(
                      session.deviceName ?? session.name ?? 'Unknown Device',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.sp,
                        vertical: 4.sp,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: AppText(
                        "Joriy",
                        fontSize: 10.sp,
                        color: context.palette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  4.verticalSpace,
                  AppText(
                    '${_getPlatformName(session.platform)} • ${session.ipAddress ?? "N/A"}',
                    fontSize: 12.sp,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  4.verticalSpace,
                  AppText(
                    session.lastUsedAt != null
                        ? _formatLastUsed(session.lastUsedAt, context)
                        : 'Foydalanilmagan',
                    fontSize: 11.sp,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ],
              ),
              trailing: isCurrent
                  ? null
                  : IconButton(
                      icon: Icon(Icons.delete_outline, color: context.isDark ? AppColors.redOnDark : AppColors.red),
                      onPressed: () {
                        AppHelpers.appAlertDialog(
                          context: context,
                          title: "Qurilmani o'chirish",
                          content: "Haqiqatan ham bu qurilmadan chiqib ketmoqchimisiz?",
                          actionTitle: "Ha, o'chirish",
                          onTap: () {
                            AppNavigator.pop();
                            try { MixpanelAnalyticsService.instance.track(MixpanelEvents.deviceRemoved, {}); } catch (_) {}
                            notifier.deleteSession(
                              sessionId: session.id ?? 0,
                              context: context,
                            );
                          },
                        );
                      },
                    ),
            ),
          );
            },
          ),

        // Delete all devices button
        if (hasOtherDevices) ...[
          16.verticalSpace,
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.sp,
                vertical: 8.sp,
              ),
              leading: Icon(
                Icons.logout,
                color: context.isDark ? AppColors.redOnDark : AppColors.red,
              ),
              title: AppText(
                "Barcha devicelarni chiqarib yuborish",
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.isDark ? AppColors.redOnDark : AppColors.red,
              ),
              subtitle: AppText(
                "Joriy qurilmadan tashqari barcha qurilmalardan chiqib ketasiz",
                fontSize: 12.sp,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              onTap: () {
                AppHelpers.appAlertDialog(
                  context: context,
                  title: "Barcha qurilmalarni o'chirish",
                  content: "Haqiqatan ham barcha boshqa qurilmalardan chiqib ketmoqchimisiz?",
                  actionTitle: "Ha, o'chirish",
                  onTap: () {
                    AppNavigator.pop();
                    notifier.deleteAllSessions(context: context);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

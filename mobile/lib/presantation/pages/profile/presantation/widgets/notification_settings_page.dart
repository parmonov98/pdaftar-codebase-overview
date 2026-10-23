import 'package:pdaftaruz/service/notifications/notification_permission_service.dart';
import 'package:app_settings/app_settings.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/injection.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import 'package:pdaftaruz/constants/app_owner_status.dart';
import 'package:pdaftaruz/presantation/pages/seller_activity/seller_activity_push_tile.dart';
import 'package:pdaftaruz/presantation/pages/seller_activity/seller_activity_group_page.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/notification_catalog/notification_catalog_controller.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/notification_catalog/notification_catalog_repository.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/notification_catalog/notification_catalog_section.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  // Toggle state mirrors the SERVER flag (user_settings.notification_enabled),
  // NOT the OS permission. The OS permission is a separate constraint we
  // surface as a hint below — but the user's own preference about whether
  // they WANT pushes lives on our backend and survives reinstalls, OS-
  // permission resets, and device swaps.
  bool _serverEnabled = false;
  // OS permission status — used only for the "Open system settings" hint
  // when the user has pushes on at the server level but the OS would
  // block delivery anyway.
  bool _osPermissionGranted = false;
  // Server-side preferred time for the daily debt reminder push.
  // Default 20:00 mirrors the legacy fixed cron time.
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _savingDailyReminderTime = false;
  // Server-side preferred time for the morning greeting push.
  TimeOfDay _morningGreetingTime = const TimeOfDay(hour: 8, minute: 0);
  bool _savingMorningGreetingTime = false;
  // Seller-activity push toggle (Trello #668). Null until the settings load,
  // and on a backend that predates it — the tile is hidden then.
  bool? _sellerActivityPush;

  // Trello #712: the server-driven groups below the push master switch.
  // On a backend without the catalog (404/405) the pre-#712 tiles show.
  late final NotificationCatalogController _catalog =
      NotificationCatalogController(
    repository: NotificationCatalogRepository(),
    initialShopId: _currentShopId(),
  );
  bool _catalogUnsupported = false;

  static const _routes = {
    'push_settings',
    'sms_settings',
    'voice_settings',
    'seller_activity_group',
    'notification_inbox',
    'news',
    'sms_history',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOsPermissionStatus();
    _loadUserSettings();
    _catalog.addListener(_onCatalogChanged);
    _catalog.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _catalog.removeListener(_onCatalogChanged);
    _catalog.dispose();
    super.dispose();
  }

  void _onCatalogChanged() {
    if (_catalog.unsupported != _catalogUnsupported && mounted) {
      setState(() => _catalogUnsupported = _catalog.unsupported);
    }
  }

  int? _currentShopId() {
    final id = LocalStorage.instance.getSelectedShopId();
    return id > 0 ? id : null;
  }

  Future<void> _openRoute(String route, int? shopId) async {
    switch (route) {
      case 'push_settings':
        await AppNavigator.push(PushSettingsRoute(shopId: shopId));
      case 'sms_settings':
        await AppNavigator.push(SmsSettingsRoute(shopId: shopId));
      case 'voice_settings':
        await AppNavigator.push(VoiceSpeechSettingsRoute(shopId: shopId));
      case 'seller_activity_group':
        if (shopId == null) return;
        await SellerActivityGroupPage.open(context, shopId);
      case 'notification_inbox':
        await AppNavigator.push(NotificationRoute(initialTabIndex: 0));
      case 'news':
        await AppNavigator.push(NotificationRoute(initialTabIndex: 1));
      case 'sms_history':
        await AppNavigator.push(const SmsHistoryRoute());
      default:
        return;
    }
    // A detail page may have changed what the summary rows show.
    if (mounted) _catalog.load();
  }

  // Refresh OS permission when returning from system settings — the
  // toggle itself doesn't change, but the "Open system settings" hint
  // should disappear if the user just granted permission externally.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOsPermissionStatus();
    }
  }

  Future<void> _refreshOsPermissionStatus() async {
    final granted = await NotificationPermissionService.instance.refresh() ==
        NotificationPermissionState.granted;
    if (!mounted) return;
    setState(() => _osPermissionGranted = granted);
  }

  Future<void> _toggleNotification(bool value) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Flip the SERVER flag first — this is the user's actual preference
    // and is what the backend reads when deciding to dispatch a push.
    final ok = await _saveToBackend(value);
    if (!mounted) return;

    if (!ok) {
      setState(() => _isLoading = false);
      AppHelpers.showSnackBarInfo(
        message:
            AppLocalization.getText(context)?.something_went_wrong ??
                'Something went wrong, please try again.',
      );
      return;
    }

    setState(() {
      _serverEnabled = value;
      _isLoading = false;
    });

    // Keep the local mirror in sync with the server. LocalStorage is used
    // by other places to short-circuit push setup without a round-trip.
    LocalStorage.instance.setNotificationEnabled(value);
    // Switched off here = a decision, so the "notifications are off" nudge
    // on home and Profil stays away until they switch it back on.
    LocalStorage.instance.setNotificationsUserOff(!value);

    if (value) {
      MixpanelAnalyticsService.instance
          .track(MixpanelEvents.notificationPermissionRequested);
      // If the OS hasn't granted permission yet, opportunistically ask.
      // Failure here is fine — the server flag is on; we just won't be
      // able to deliver pushes until the OS permission is also granted.
      // We surface that gap via the hint below the toggle.
      if (!_osPermissionGranted) {
        try {
          // Opens system Settings where the OS will no longer show a
          // dialog. "Granted" is tracked by the service's listener.
          final granted = await NotificationPermissionService.instance.request();
          if (!mounted) return;
          setState(() => _osPermissionGranted = granted);
          if (!granted) {
            MixpanelAnalyticsService.instance
                .track(MixpanelEvents.notificationPermissionDenied);
          }
        } catch (_) {
          // ignore — OS prompt may not be available; hint below covers it.
        }
      }
    }
  }

  /// Returns true on success, false on any failure. Caller decides whether
  /// to roll back the in-memory toggle state.
  Future<bool> _saveToBackend(bool enabled) async {
    try {
      final res = await inject<ProfileRepository>()
          .updateNotificationEnabled(enabled: enabled);
      bool success = false;
      res.when(
        success: (_) => success = true,
        failure: (_, __, ___) => success = false,
      );
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadUserSettings() async {
    try {
      final res = await inject<ProfileRepository>().getUserSettings();
      res.when(
        success: (data) {
          if (data is! Map || data['data'] is! Map) return;
          final body = data['data'] as Map;

          final eveningRaw = body['daily_reminder_time']?.toString() ?? '20:00:00';
          final morningRaw = body['morning_greeting_time']?.toString() ?? '08:00:00';
          final evening = _parseTime(eveningRaw, fallbackHour: 20);
          final morning = _parseTime(morningRaw, fallbackHour: 8);
          // user_settings.notification_enabled — the source of truth for
          // whether the user wants pushes. May be null on rows seeded
          // before this column existed; treat null as off (safer default
          // than spamming notifications based on the OS permission).
          final serverEnabled = body['notification_enabled'] == true;
          final sellerActivity = body['seller_activity_push_enabled'];
          if (!mounted) return;
          setState(() {
            _sellerActivityPush = sellerActivity is bool ? sellerActivity : null;
            _dailyReminderTime = evening;
            _morningGreetingTime = morning;
            _serverEnabled = serverEnabled;
          });
          // Mirror to LocalStorage so other parts of the app reading
          // the cached flag see the freshly-loaded server value.
          LocalStorage.instance.setNotificationEnabled(serverEnabled);
        },
        failure: (_, __, ___) {},
      );
    } catch (_) {}
  }

  TimeOfDay _parseTime(String raw, {required int fallbackHour}) {
    final parts = raw.split(':');
    if (parts.length < 2) return TimeOfDay(hour: fallbackHour, minute: 0);
    final h = int.tryParse(parts[0]) ?? fallbackHour;
    final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _pickDailyReminderTime() async {
    if (_savingDailyReminderTime) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyReminderTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dailyReminderTime = picked;
      _savingDailyReminderTime = true;
    });
    try {
      await inject<ProfileRepository>()
          .updateDailyReminderTime(time: _formatHm(picked));
    } catch (_) {}
    if (mounted) setState(() => _savingDailyReminderTime = false);
  }

  Future<void> _pickMorningGreetingTime() async {
    if (_savingMorningGreetingTime) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _morningGreetingTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _morningGreetingTime = picked;
      _savingMorningGreetingTime = true;
    });
    try {
      await inject<ProfileRepository>()
          .updateMorningGreetingTime(time: _formatHm(picked));
    } catch (_) {}
    if (mounted) setState(() => _savingMorningGreetingTime = false);
  }

  String _formatHm(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0, 0),
        child: AppBar(
          systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(1000),
                    onTap: AppNavigator.pop,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: CustomSvgWidgetAsset(
                          Assets.arrowRightIconSvg,
                          isFlag: false,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AppText(
                        l?.notification_settings ?? 'Notification Settings',
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  // Spacer to balance the back button
                  const SizedBox(width: 40),
                ],
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24.h),
                children: [
                  // Push notification toggle tile
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications_outlined,
                          color: context.palette.accent,
                          size: 22.sp,
                        ),
                        title: AppText(
                          l?.push_notifications ?? 'Push Notifications',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        subtitle: AppText(
                          l?.push_notifications_description ??
                              'Get notified about new debts and payments',
                          fontSize: 12.sp,
                          color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                        ),
                        trailing: _isLoading
                            ? SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      context.palette.accent),
                                ),
                              )
                            : Transform.scale(
                                scale: 0.85,
                                child: Switch.adaptive(
                                  // Bound to the SERVER flag so the toggle
                                  // reflects user_settings.notification_enabled
                                  // regardless of OS permission state. The OS
                                  // gap is surfaced as a hint below.
                                  value: _serverEnabled,
                                  onChanged: _toggleNotification,
                                  activeThumbColor: Theme.of(context).primaryColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Hint when the user has pushes ON at the server level but
                  // the OS is blocking delivery. Hidden when notifications are
                  // off server-side (then the OS state doesn't matter) and
                  // when both are aligned.
                  if (_serverEnabled && !_osPermissionGranted)
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                      child: GestureDetector(
                        onTap: () => AppSettings.openAppSettings(
                            type: AppSettingsType.notification),
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined,
                                size: 14.sp, color: context.palette.accent),
                            6.horizontalSpace,
                            Expanded(
                              child: AppText(
                                l?.open_system_settings ?? 'Open System Settings',
                                fontSize: 12.sp,
                                color: context.palette.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_catalogUnsupported)
                    NotificationCatalogSection(
                      controller: _catalog,
                      canOpenRoute: _routes.contains,
                      onOpenRoute: _openRoute,
                    )
                  else ...[
                    // Daily-reminder time picker. Only meaningful when push is
                    // actually enabled — disabled & dimmed when OS permission is
                    // off (a reminder time can't fire without permission).
                    12.verticalSpace,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListTile(
                          enabled: _serverEnabled && !_savingDailyReminderTime,
                          leading: Icon(
                            Icons.schedule_outlined,
                            color: context.palette.accent,
                            size: 22.sp,
                          ),
                          title: AppText(
                            l?.daily_reminder_time_title ??
                                'Eslatma vaqti',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          subtitle: AppText(
                            l?.daily_reminder_time_desc ??
                                "Qarzlar haqida har kuni qachon eslatma yuborilishini tanlang",
                            fontSize: 12.sp,
                            color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                          ),
                          trailing: _savingDailyReminderTime
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.h,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        context.palette.accent),
                                  ),
                                )
                              : AppText(
                                  _formatHm(_dailyReminderTime),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.accent,
                                ),
                          onTap: _serverEnabled ? _pickDailyReminderTime : null,
                        ),
                      ),
                    ),
                    // Morning greeting time picker — independent from the
                    // evening reminder, same gating rules.
                    8.verticalSpace,
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListTile(
                          enabled: _serverEnabled && !_savingMorningGreetingTime,
                          leading: Icon(
                            Icons.wb_sunny_outlined,
                            color: context.palette.accent,
                            size: 22.sp,
                          ),
                          title: AppText(
                            l?.morning_greeting_time_title ??
                                'Tongi salomlashish vaqti',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          subtitle: AppText(
                            l?.morning_greeting_time_desc ??
                                "Har kuni ertalab qachon salomlashish bildirishnomasi yuborilishi",
                            fontSize: 12.sp,
                            color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                          ),
                          trailing: _savingMorningGreetingTime
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.h,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        context.palette.accent),
                                  ),
                                )
                              : AppText(
                                  _formatHm(_morningGreetingTime),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.palette.accent,
                                ),
                          onTap:
                              _serverEnabled ? _pickMorningGreetingTime : null,
                        ),
                      ),
                    ),
                    // Owners with sellers: a push per seller action (Trello #668).
                    if (_sellerActivityPush != null &&
                        AppOwnerStatus.status(LocalStorage.instance.getUserType())) ...[
                      8.verticalSpace,
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SellerActivityPushTile(value: _sellerActivityPush!),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

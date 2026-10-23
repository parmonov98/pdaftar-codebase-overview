import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/presantation/pages/gamification/data/shop_features.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/game_feel_settings_rows.dart';
import 'package:pdaftaruz/presantation/pages/community/riverpod/community_chat_provider.dart';
import 'package:pdaftaruz/presantation/pages/community/community_page.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/restarter_widget.dart';
import 'package:pdaftaruz/presantation/pages/linked_accounts/widgets/account_sign_out.dart';
import 'package:pdaftaruz/presantation/pages/notification/presentation/riverpod/provider/notification_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/font_size_modal.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/leave_business_row.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_ambassador_section.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_social_row.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_row.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_section.dart';
import 'package:pdaftaruz/service/dev/dev_backend_switcher_tile.dart';
import 'package:pdaftaruz/service/remote_config/remote_config_service.dart';

/// The static settings column of the Profil menu (Hamjamiyat + Ambassador +
/// Hisob + Sozlamalar + Bildirishnomalar + Yordam sections, social row,
/// sign-out, version footer). Extracted from [ProfilePageMenu].
///
/// Perf: this ~35-row column used to be inlined in the menu's build, so
/// every profileProvider / homeProvider emission during the first-open API
/// burst reconstructed all of it. As a `const` child it is skipped
/// entirely when the parent rebuilds; the only providers that rebuild it
/// are the ones it actually renders — notificationProvider (shimmer +
/// unread badge, watched via narrow selects) and the two per-row
/// mainProvider tab toggles (scoped Consumers with selects).
class ProfileSettingsSections extends ConsumerWidget {
  const ProfileSettingsSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No skeleton over this column. It used to follow
    // notificationProvider.isLoading, which the first-open burst flips twice
    // (notificationCount at 300 ms, getNotification at 600 ms); each flip
    // swapped the whole ~35-row subtree to a grey block and back — the
    // Profil "glitch". The rows are static; only the badge needs data.
    final unreadCount = ref.watch(
        notificationProvider.select((s) => s.notificationCount?.unread));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── HAMJAMIYAT (pinned top, above Ambassador — #565) ───
          SettingsSection(
            title: AppLocalization.getText(context)!.community_title,
            children: [
              // The pill counts unread community messages and updates over
              // the socket, so it moves while the user is on this screen —
              // watching the notifier rather than rebuilding the page.
              ValueListenableBuilder<int>(
                valueListenable: ref.watch(communityInboxProvider).unread,
                builder: (context, unread, _) => SettingsRow(
                  title: AppLocalization.getText(context)!.community_title,
                  iconAsset: Assets.profileIconSvg,
                  notificationCount: unread > 0 ? unread : null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CommunityPage(),
                  )),
                ),
              ),
              // Nishonlarim (#711): for sellers too, who have no top grid.
              ValueListenableBuilder<bool>(
                valueListenable: ShopFeatures.instance.badgesOn,
                builder: (context, on, _) => on
                    ? SettingsRow(
                        title: AppLocalization.getText(context)?.badges_title ??
                            'Nishonlarim',
                        iconAsset: Assets.profileIconSvg,
                        onTap: () => AppNavigator.push(const BadgesRoute()),
                      )
                    : const SizedBox.shrink(),
              ),
              // Reyting (#711).
              ValueListenableBuilder<bool>(
                valueListenable: ShopFeatures.instance.rankingOn,
                builder: (context, on, _) => on
                    ? SettingsRow(
                        title: AppLocalization.getText(context)?.ranking_title ??
                            'Oylik reyting',
                        iconAsset: Assets.chartSvg,
                        onTap: () => AppNavigator.push(const RankingRoute()),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          // ─── UGC AMBASSADOR ─────────────────────────────────
          // Right under Hamjamiyat (Trello #565): the community room sits
          // first, the earn opportunity second, then account/settings.
          const ProfileAmbassadorSection(),

          // ACCOUNT
          SettingsSection(
            title:
                AppLocalization.getText(context)?.section_account ?? 'Hisob',
            children: [
              SettingsRow(
                title: AppLocalization.getText(context)?.profile_settings ??
                    'Profil sozlamalari',
                iconAsset: Assets.profileIconSvg,
                onTap: () => AppNavigator.push(const ProfileSettingsRoute()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.security_settings ??
                    'Xavfsizlik',
                iconAsset: Assets.securityIconSvg,
                onTap: () => AppNavigator.push(const SecuritySettingsRoute()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.change_password ??
                    'Parolni o\'zgartirish',
                iconAsset: Assets.passwordIconSvg,
                onTap: () => AppNavigator.push(const ChangePasswordRoute()),
              ),
              SettingsRow(
                title: 'Qurilmalar',
                iconAsset: Assets.phoneIconSvg,
                onTap: () => AppNavigator.push(const DevicesRoute()),
              ),
              // Seller in someone else's business, with another to go to.
              const LeaveBusinessRow(),
            ],
          ),

          // PREFERENCES
          SettingsSection(
            title: AppLocalization.getText(context)?.section_preferences ??
                'Sozlamalar',
            children: [
              // Dedicated SMS settings page — first row so the SMS block
              // (master toggle, reminders, gateway, templates) is
              // prominent instead of buried inside Shop Info tabs.
              SettingsRow(
                title: AppLocalization.getText(context)
                        ?.sms_settings_page_title ??
                    'SMS sozlamalari',
                iconAsset: Assets.messageIconSvg,
                isNew: true,
                onTap: () => AppNavigator.push(SmsSettingsRoute()),
              ),
              // Push settings got the same treatment as SMS: they used to
              // sit inline at the bottom of Qarz Sozlamalari, where the
              // debt toggles buried them.
              SettingsRow(
                title: AppLocalization.getText(context)
                        ?.push_settings_page_title ??
                    'Push sozlamalari',
                iconAsset: Assets.notificationIconSvg,
                isNew: true,
                onTap: () => AppNavigator.push(PushSettingsRoute()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)
                        ?.voice_settings_page_title ??
                    "Ovozli qo'ng'iroq sozlamalari",
                iconAsset: Assets.phoneIconSvg,
                isNew: true,
                onTap: () => AppNavigator.push(VoiceSpeechSettingsRoute()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.lang ?? 'Til',
                iconAsset: Assets.languageIconSvg,
                onTap: () => AppHelpers.showCustomModalBottomSheet(
                    context: context, modal: const ChangeLangModal()),
              ),
              // Game feel A/B (#711): shown only to shops in the
              // treatment group, where there is something to switch off.
              const GameFeelSettingsRows(),
              SettingsRow(
                title:
                    AppLocalization.getText(context)?.themes ?? 'Mavzular',
                iconAsset: Assets.themeIconSvg,
                onTap: () => AppHelpers.showCustomModalBottomSheet(
                    context: context, modal: const ChangeThemeModal()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.font_size ??
                    'Shrift o\'lchami',
                iconAsset: Assets.themeIconSvg,
                isNew: true,
                onTap: () => AppHelpers.showCustomModalBottomSheet(
                    context: context, modal: const FontSizeModal()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.home_screen_widgets ??
                    'Bosh ekran widgetlari',
                // Reuse the existing app-icon SVG — closest to a
                // "shortcut" / "home screen" affordance in the
                // asset library without adding a new file.
                iconAsset: Assets.phoneIconSvg,
                isNew: true,
                onTap: () => AppNavigator.push(const HomeWidgetsRoute()),
              ),
              // Per-user toggles for the Kassa + Mahsulot bottom-
              // nav tabs. Also reachable via a 3-second long-press
              // on the tab itself; mirrored here so a hidden tab
              // can always be brought back. Default ON.
              //
              // select() keeps these rows quiet when unrelated main
              // state (page index on every tab switch) changes.
              Consumer(builder: (context, ref, _) {
                final showKassaTab = ref.watch(
                    mainProvider(0).select((s) => s.showKassaTab));
                return SettingsRow(
                  title: AppLocalization.getText(context)?.show_kassa_tab ??
                      'Kassa tabi',
                  iconAsset: Assets.cashRegisterIconSvg,
                  onTap: () => ref
                      .read(mainProvider(0).notifier)
                      .setShowKassaTab(!showKassaTab),
                  trailing: Switch.adaptive(
                    value: showKassaTab,
                    activeThumbColor: AppColors.primaryColor,
                    onChanged: (v) => ref
                        .read(mainProvider(0).notifier)
                        .setShowKassaTab(v),
                  ),
                );
              }),
              Consumer(builder: (context, ref, _) {
                final showMahsulotTab = ref.watch(
                    mainProvider(0).select((s) => s.showMahsulotTab));
                return SettingsRow(
                  title:
                      AppLocalization.getText(context)?.show_mahsulot_tab ??
                          'Mahsulot tabi',
                  iconAsset: Assets.skladIconSvg,
                  onTap: () => ref
                      .read(mainProvider(0).notifier)
                      .setShowMahsulotTab(!showMahsulotTab),
                  trailing: Switch.adaptive(
                    value: showMahsulotTab,
                    activeThumbColor: AppColors.primaryColor,
                    onChanged: (v) => ref
                        .read(mainProvider(0).notifier)
                        .setShowMahsulotTab(v),
                  ),
                );
              }),
            ],
          ),

          // NOTIFICATIONS
          SettingsSection(
            title: AppLocalization.getText(context)?.section_notifications ??
                'Bildirishnomalar va yangiliklar',
            children: [
              SettingsRow(
                title: AppLocalization.getText(context)?.notification ??
                    'Bildirishnomalar',
                iconAsset: Assets.notificationIconSvg,
                notificationCount: unreadCount,
                onTap: () =>
                    AppNavigator.push(NotificationRoute(initialTabIndex: 0)),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.news ??
                    'Yangiliklar',
                iconAsset: Assets.infoSvg,
                onTap: () =>
                    AppNavigator.push(NotificationRoute(initialTabIndex: 1)),
              ),
              SettingsRow(
                title:
                    AppLocalization.getText(context)?.notification_settings ??
                        'Bildirishnoma sozlamalari',
                iconAsset: Assets.notificationIconSvg,
                isNew: true,
                onTap: () =>
                    AppNavigator.push(const NotificationSettingsRoute()),
              ),
              SettingsRow(
                title:
                    AppLocalization.getText(context)?.printer_settings_title ??
                        'Printer sozlamalari',
                iconAsset: Assets.printerIconSvg,
                isNew: true,
                onTap: () => AppNavigator.push(const PrinterSettingsRoute()),
              ),
            ],
          ),

          // SUPPORT & ABOUT
          SettingsSection(
            title: AppLocalization.getText(context)?.section_support ??
                'Yordam va ilova',
            children: [
              SettingsRow(
                title: AppLocalization.getText(context)?.faq ?? 'FAQ',
                iconAsset: Assets.faqIconSvg,
                onTap: () => AppNavigator.push(const FaqRoute()),
              ),
              SettingsRow(
                title: AppLocalization.getText(context)?.tg_channel ??
                    'Telegram channel',
                iconAsset: Assets.telegramIconSvg,
                onTap: () =>
                    ProfileSocialRow.launchExternal(Assets.telegramChannelLink),
              ),
              // Telegram channel / Instagram / Phone-call surfaces
              // restored as a 3-button social row below — keeps
              // the existing visual cue users are familiar with.
              // Rate / Share are tiles near the top of Profil
              // (ProfileAppActionsRow); support is the floating bubble.
            ],
          ),

          // ── Social networks row ─────────────────────────────
          10.verticalSpace,
          const ProfileSocialRow(),

          // SIGN OUT (destructive)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Container(
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    SettingsRow(
                      title: AppLocalization.getText(context)?.exit_account ??
                          'Hisobdan chiqish',
                      iconAsset: Assets.logOutIconSvg,
                      destructive: true,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                    // Several accounts on the device (#542).
                    LogoutAllAccountsRow(
                        onFullLogout: () => _fullLogout(context, ref)),
                  ],
                ),
              ),
            ),
          ),

          // App version footer
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Center(
              child: AppText(
                "${AppLocalization.getText(context)?.app_version}: ${RemoteConfigService.appVersion}",
                color: context.palette.textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ),

          // Debug-only backend switcher. Renders nothing in a
          // release build — see DevBackendSwitcher.isAvailable.
          const DevBackendSwitcherTile(),
        ],
      ),
    );
  }

  /// Logout flow — triggered from the destructive "Sign out" row at the
  /// bottom of the settings list.
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    AppHelpers.appAlertDialog(
      actionTitle: "${AppLocalization.getText(context)?.yes_logout}",
      context: context,
      title:
          "${AppLocalization.getText(context)?.do_you_really_want_to_go_out}",
      content: AccountSignOut.confirmBody(context,
          "${AppLocalization.getText(context)?.exit_from_account_content}"),
      onTap: () async {
        AppNavigator.pop();
        // With other accounts on the device only this one signs out and
        // the next one opens (#542).
        if (await AccountSignOut.signOutActiveOnly()) return;
        if (!context.mounted) return;
        await _fullLogout(context, ref);
      },
    );
  }

  /// Today's sign-out: erase the session and land on Auth.
  Future<void> _fullLogout(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(profileProvider.notifier);
    notifier.restoreSetting();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;
    ref.read(mainProvider(0).notifier).incrementPageIndex(0);
    AppNavigator.pushAndPopUntil(AuthRoute(initialTabIndex: 1));
    await Future.delayed(const Duration(milliseconds: 50));
    if (!context.mounted) return;
    RestartWidget.restartApp(context);
    AppHelpers.showSnackBarSuccess(
      message: '${AppLocalization.getText(context)?.exit_completed}',
    );
  }
}

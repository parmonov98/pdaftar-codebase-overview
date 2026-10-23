import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_top_up_bottom_sheet.dart';
import 'package:pdaftaruz/presantation/pages/gamification/data/shop_features.dart';
import 'package:pdaftaruz/constants/app_owner_status.dart';
import 'package:pdaftaruz/presantation/global_widgets/notifications_off_strip.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/widgets/user_limits_accordion.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';
import 'package:pdaftaruz/service/page_visit_logger.dart';
import 'package:pdaftaruz/presantation/global_widgets/app_shimmer_widget.dart';
import 'package:pdaftaruz/presantation/global_widgets/tariff_expiring_banner.dart';
import 'package:pdaftaruz/presantation/global_widgets/tariff_extend_flow.dart';
import 'package:pdaftaruz/presantation/pages/social_tasks/riverpod/social_task_provider.dart';
import 'package:pdaftaruz/presantation/pages/ugc/presantation/riverpod/ugc_notifier.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:pdaftaruz/presantation/pages/notification/presentation/riverpod/provider/notification_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/user_info_response.dart';
import 'package:pdaftaruz/service/telegram/owner_telegram_link_service.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_settings_sections.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_app_actions_row.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/quick_actions_grid.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/wallet_strip.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/trial_sms_notice_sheet.dart';
import 'package:pdaftaruz/presantation/pages/linked_accounts/widgets/account_switcher_sheet.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class ProfilePageMenu extends ConsumerStatefulWidget {
  const ProfilePageMenu({super.key});

  @override
  ConsumerState<ProfilePageMenu> createState() => _ProfilePageMenuState();
}

class _ProfilePageMenuState extends ConsumerState<ProfilePageMenu> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifier = ref.read(profileProvider.notifier);
      final notifier2 = ref.read(notificationProvider.notifier);
      final homeNotifier = ref.read(homeProvider(0).notifier);

      // Critical info first
      notifier.getUserInfo();

      // Pacing other calls to avoid blocking UI main thread
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          notifier.getWalletBalance();
          notifier2.notificationCount();
        }
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          notifier2.getNotification();
          notifier.getAppVersion();
          homeNotifier.checkOwnerTariffs();
        }
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          // Shops info might already be loaded from Home, only fetch if needed
          homeNotifier.getUserShops(context: context);
          notifier.initPinKey();
        }
      });

      // Ambassador-row count chips: load social tasks + active UGC
      // campaign + the user's video submissions so we can render
      // "remaining" badges on the Vazifalar / Video yozish rows.
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          ref.read(socialTaskProvider.notifier).loadTasks();
          ref.read(ugcProvider.notifier).loadActiveCampaign();
          ref.read(ugcProvider.notifier).loadSubmissions();
        }
      });

      notifier.phoneController.text =
          LocalStorage.instance.getPhoneNumber().format.replaceAll("+998 ", "");
      notifier.nameController.text = LocalStorage.instance.getUserName();

      // Log page visit
      PageVisitLogger().logPageVisit('ProfilePageMenu');
    });
  }

  @override
  Widget build(BuildContext context) {
    // ProfileState has ~40 fields and its notifier flips loading flags
    // through the first-open API burst — watching the whole state made
    // this ~670-line build re-run 15-20x. Narrow to the four fields the
    // menu actually renders (same for the notification badge below).
    final state = ref.watch(profileProvider.select((s) => (
          userInfoData: s.userInfoData,
          sellerOwnerData: s.sellerOwnerData,
          balanceHistory: s.balanceHistory,
          isUpdateLoading: s.isUpdateLoading,
        )));
    // Only the unread badge count is rendered at this level — the settings
    // column (whose shimmer needs isLoading) watches notificationProvider
    // itself in ProfileSettingsSections. notificationCount() and
    // getNotification() each flip isLoading true/false on first open, so
    // keeping isLoading out of this watch saves 4 full-page rebuilds.
    final unreadCount = ref.watch(
        notificationProvider.select((s) => s.notificationCount?.unread ?? 0));
    final subState = ref.watch(homeProvider(0).select((s) => (
          ownerTariffsCheck: s.ownerTariffsCheck,
          walletBalance: s.ownerTariffsCheck?.data?.owner?.walletBalance,
        )));
    // Header keeps the seller's OWN identity (name/phone/avatar +
    // "Sotuvchi" pill). The balance + SMS + referral cards underneath
    // already reflect the owner's data (resolved server-side via
    // /owner/sub/get-active when the auth user is seller-only), so we
    // add an attribution hint between the header and those cards
    // saying "These limits belong to <Owner Name>" — explicit so the
    // seller isn't confused about whose balance they're looking at.
    //
    // `sellerOwnerData` stays null for owners, who see the hint hidden.
    final isSeller = !AppOwnerStatus.status(
      state.userInfoData?.userType ?? LocalStorage.instance.getUserType(),
    );
    // Trello #694: a trial that withholds the tariff's SMS package says so
    // once. Only while Profil is the selected tab (the tab stack keeps
    // hidden tabs alive) and nothing sits on top of it (the trial dialog,
    // another sheet), so it never competes with another overlay.
    final ownerSub = subState.ownerTariffsCheck?.data;
    final isProfileTab =
        ref.watch(mainProvider(0).select((s) => s.indexPage == 4));
    if (!isSeller &&
        isProfileTab &&
        ownerSub?.isTrial == true &&
        (ownerSub?.trialWithheldSmsCount ?? 0) > 0 &&
        (ModalRoute.of(context)?.isCurrent ?? true)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) TrialSmsNoticeSheet.maybeShow(context, ownerSub);
      });
    }
    final displayName = LocalStorage.instance.getUserName();
    final displayPhone = LocalStorage.instance.getPhoneNumber().format;
    final displayImage = state.userInfoData?.data?.image ??
        'https://upload.wikimedia.org/wikipedia/commons/b/bc/Unknown_person.jpg';

    final leftSms = (subState.ownerTariffsCheck?.data?.smsCount ?? 0) -
        (subState.ownerTariffsCheck?.data?.usedSms ?? 0);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 6,
          ),
        ),
        // Account actions + the limits accordion, pinned under the
        // identity row. Limits used to live in the home app bar and
        // expanded the Asosiy card; it belongs with the account, and
        // bouncing the user to another tab to read their own limits was
        // the wrong interaction.
        SliverToBoxAdapter(
          child: ListTile(
            minTileHeight: 10,
            // Several accounts in one app (#542): the account list lives
            // here, Telegram-style — not in the left drawer, which switches
            // shops of this same account.
            onTap: () => AccountSwitcherSheet.show(context,
                activeAvatarUrl: state.userInfoData?.data?.image),
            leading: CustomShimmerEffect(
              isLoading: state.isUpdateLoading,
              child: !isSeller
                  ? GestureDetector(
                      onTap: () {
                        MixpanelAnalyticsService.instance
                            .track(MixpanelEvents.upgradeTariffClicked, {
                          'Source': 'profile_menu',
                        });
                        AppNavigator.push(const OwnerTariffRoute());
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.sp),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF58529),
                                  Color(0xFFDD2A7B),
                                  Color(0xFF8134AF),
                                  Color(0xFF515BD4),
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).scaffoldBackgroundColor,
                              radius: 30,
                              backgroundImage: NetworkImage(displayImage),
                            ),
                          ),
                          Positioned(
                              left: 12,
                              right: 12,
                              top: 39,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFF58529),
                                      Color(0xFFDD2A7B),
                                      Color(0xFF8134AF),
                                      Color(0xFF515BD4),
                                    ],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: AppText(
                                  subState.ownerTariffsCheck?.data?.tariff
                                          ?.name ??
                                      "",
                                  fontSize: 10,
                                  color: AppColors.white,
                                ),
                              )),
                        ],
                      ),
                    )
                  : GestureDetector(
                      onTap: () {
                        MixpanelAnalyticsService.instance
                            .track(MixpanelEvents.upgradeTariffClicked, {
                          'Source': 'profile_menu',
                        });
                        AppNavigator.push(const OwnerTariffRoute());
                      },
                      child: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        radius: 30,
                        backgroundImage: NetworkImage(displayImage),
                      ),
                    ),
            ),
            title: CustomShimmerEffect(
              isLoading: state.isUpdateLoading,
              child: AppText(
                displayName,
                maxLines: 1,
                fontSize: 16.sp,
              ),
            ),
            subtitle: CustomShimmerEffect(
              isLoading: state.isUpdateLoading,
              child: displayPhone.isNotEmpty
                  ? AppText(
                      displayPhone,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    )
                  : const SizedBox.shrink(),
            ),
            // Role badge — Owner → "Biznes egasi", Seller → "Sotuvchi".
            // Falls back to LocalStorage when userInfoData hasn't hydrated
            // yet so the pill never flashes blank on cold start.
            trailing: () {
              final type = state.userInfoData?.userType ??
                  LocalStorage.instance.getUserType();
              final label = AppOwnerStatus.roleLabel(type, context);
              final switchHint = Icon(Icons.unfold_more_rounded,
                  size: 20, color: context.palette.textSecondary);
              if (label.isEmpty) return switchHint;
              final isOwner = AppOwnerStatus.status(type);
              final pillColor =
                  isOwner ? context.palette.accent : AppColors.green;
              final pill = Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: pillColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: pillColor.withValues(alpha: 0.4), width: 0.6),
                ),
                child: AppText(
                  label,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: pillColor,
                  maxLines: 1,
                ),
              );
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [pill, 2.horizontalSpace, switchHint],
              );
            }(),
          ),
        ),
        // Account actions: notifications + limits, right under the identity
        // row. Tapping Limitlar expands the accordion IN PLACE below this
        // row — it no longer jumps to Asosiy.
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
            child: Row(
              children: [
                _ProfileTopAction(
                  icon: Icons.notifications_none_rounded,
                  label: AppLocalization.getText(context)?.notification ??
                      'Bildirishnomalar',
                  badgeCount: unreadCount,
                  onTap: () => AppNavigator.push(NotificationRoute(initialTabIndex: 0)),
                ),
                10.w.horizontalSpace,
                _ProfileTopAction(
                  icon: Icons.data_usage_rounded,
                  label: AppLocalization.getText(context)
                          ?.profile_limits_title ??
                      'Limitlar va tarif',
                  onTap: () => ref
                      .read(homeProvider(0).notifier)
                      .toggleLimitsAccordion(),
                ),
              ],
            ),
          ),
        ),
        // The accordion itself — same widget the home page used, so the
        // limits UI is not duplicated.
        const SliverToBoxAdapter(child: UserLimitsAccordion()),

        // Inviter Section — shown only when the backend tells us this user was
        // referred by someone (state.userInfoData.data.inviter != null).
        // Source of truth: UserResource::resolveInviter on the backend.
        if (state.userInfoData?.data?.inviter != null)
          SliverToBoxAdapter(
            child: _InviterTile(inviter: state.userInfoData!.data!.inviter!),
          ),
        // Owner-attribution banner (sellers only). The Asosiy Balans /
        // Referal hisob / SMS cards below resolve to the OWNER's data
        // on the backend, so we annotate explicitly to prevent
        // sellers from thinking the numbers are their own.
        if (isSeller && state.sellerOwnerData != null)
          SliverToBoxAdapter(
            child: _OwnerAttributionBanner(
              ownerName: state.sellerOwnerData?.name ?? '',
            ),
          ),
        // ── Wallet strip ────────────────────────────────────────────────
        // Layout per the latest design pass:
        //   [Hisob (+)] [Referal (→)]
        //   [SMS X / Y                        (+)]
        // Tapping the SMS card itself opens the SMS history route, so the
        // separate "SMS tarixi" quick action is no longer needed; the
        // bigger gradient + button on the Hisob card replaces "To'ldirish".
        SliverToBoxAdapter(
          child: WalletStrip(
            // Wallet balance (UZS) — comes from ownerTariffsCheck.owner,
            // *not* `balanceHistory.totalBalance` (that field is the
            // referral bonus pot — see ReferralBonusResponse in
            // balance_history_response.dart). Reusing the same source
            // for both cards is what made them display identical numbers.
            balance: subState.walletBalance?.toDouble(),
            smsLeft: leftSms,
            smsTotal: subState.ownerTariffsCheck?.data?.smsCount ?? 0,
            tariffName: subState.ownerTariffsCheck?.data?.tariff?.name,
            smsWarning: _smsWarning(context, subState),
            // Referral cash earned. The balance-history endpoint named
            // `totalBalance` actually returns the referral pot; we read
            // it via state.balanceHistory when the full list is loaded, and
            // otherwise from the total getReferralBalance() stored.
            referralBalance: state.balanceHistory?.totalBalance?.toDouble() ??
                double.tryParse(LocalStorage.instance.getReferralBalance()),
            isLoading: state.isUpdateLoading,
            // Wallet top-up must not happen in-app (App Store / Play
            // payments policy). The balance chip's Telegram button opens
            // @pDaftarBot — the owner tops up there, outside the app.
            onTopUp: () => OwnerTelegramLinkService.instance
                .openBot(context, needsLinking: true),
            onBuySms: () => AppNavigator.push(const SmsTariffRoute()),
            onSmsHistory: () => AppNavigator.push(const SmsHistoryRoute()),
            onReferral: () => AppNavigator.push(const UserReferralCodeRoute()),
            onBalanceHistory: () =>
                AppNavigator.push(const WalletBalanceHistoryRoute()),
          ),
        ),

        // ── Tariff expiry banner ───────────────────────────────────────
        // Surfaced 5 days before the paid tariff lapses so the owner can
        // renew without leaving the profile tab.
        if (AppOwnerStatus.status(state.userInfoData?.userType))
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TariffExpiringBanner(
                // In grace: the same grace banner as home (owner decision 1).
                graceSubscription: subState.ownerTariffsCheck?.data,
                onTopUp: () => ProfileTopUpBottomSheet.open(context),
                expireDate: subState.ownerTariffsCheck?.data?.expireDate,
                isFreeTariff:
                    subState.ownerTariffsCheck?.data?.tariff?.isFree == true,
                isTrial: subState.ownerTariffsCheck?.data?.isTrial == true,
                walletBalance:
                    subState.ownerTariffsCheck?.data?.owner?.walletBalance,
                renewPrice:
                    subState.ownerTariffsCheck?.data?.tariff?.uzsPrice,
                onExtend: () => _confirmExtendTariff(context, ref, subState),
                margin: EdgeInsets.only(bottom: 8.h),
              ),
            ),
          ),

        // Notifications-off nudge. Not dismissible here: Profil is where it
        // stays once the user has snoozed it away from home. Renders
        // nothing while notifications are allowed.
        SliverToBoxAdapter(
          child: NotificationsOffStrip(
            placement: 'profile',
            margin: EdgeInsets.symmetric(horizontal: 16.w)
                .copyWith(bottom: 8.h),
          ),
        ),

        // ── Tariff warning banner ───────────────────────────────────────
        // Sits directly under the SMS card so the "SMS limiti kam qoldi"
        // copy reads as a continuation of that tile rather than floating
        // somewhere below the quick-actions block.
        if (AppOwnerStatus.status(state.userInfoData?.userType))
          SliverToBoxAdapter(
            child: _MaybeWarningBanner(
              subState: subState,
              builder: _buildWarningMessage,
            ),
          ),

        // ── Quick actions (owner-only) ──────────────────────────────────
        // Two tiles side by side: Mening bizneslarim and Foydalanuvchilar.
        // Extracted to _OwnerQuickActions so the shop/seller count watches
        // rebuild only the grid when those lists load, not this whole
        // scroll view.
        // Gated on the cached role until getUserInfo answers (same fallback
        // as the role badge): gating on userInfoData alone inserted this
        // row ~1 s after open and shoved the whole list down.
        if (!isSeller)
          const SliverToBoxAdapter(
            child: _OwnerQuickActions(),
          ),

        // ── Baholash / Ulashish ─────────────────────────────────────────
        // In the list, not floating over it (#591). AI yordamchi is the
        // app-wide floating bubble (#619).
        const SliverToBoxAdapter(child: ProfileAppActionsRow()),

        // ── Settings sections ────────────────────────────────────────────
        // Const child: none of this scroll view's rebuild triggers
        // (profile / home / tariff emissions) re-run the ~35-row settings
        // column — it watches notificationProvider (shimmer + unread
        // badge) and the tab toggles itself. See ProfileSettingsSections.
        const SliverToBoxAdapter(child: ProfileSettingsSections()),

        // "Hisobdan chiqish" scrolls clear of the floating glass nav.
        const SliverNavBarInset(),
      ],
    );
  }

  /// "Yangilash" tap on the tariff-expiring banner. Confirms the spend in a
  /// dialog (so a bumped tap doesn't silently charge the wallet) and then
  /// hits the same `POST /owner/orders/store` endpoint that the Obuna page
  /// uses — when the requested tariff matches the active one, the backend
  /// treats the call as an EXTENSION rather than a fresh purchase.
  void _confirmExtendTariff(
      BuildContext context, WidgetRef ref, dynamic subState) {
    // Shared one-tap renewal — same dialog now also reached from the
    // Home banner and the Tariff-page banner. See
    // `TariffExtendFlow.show` for the period math, pay-method
    // selector, and the fallback to OwnerTariffRoute when the
    // current sub state isn't extendable.
    TariffExtendFlow.show(context, ref, subState);
  }

  Widget _buildWarningMessage(BuildContext context, dynamic state) {
    final clientReportLimit =
        state.ownerTariffsCheck?.data?.clientReportLimit ?? 0;
    final clientReportCount =
        state.ownerTariffsCheck?.data?.clientReportCount ?? 0;
    final clientReportsLeft = clientReportLimit - clientReportCount;
    final clientReportRatio =
        clientReportLimit > 0 ? clientReportsLeft / clientReportLimit : 1.0;
    final tariffName = state.ownerTariffsCheck?.data?.tariff?.name ?? "";
    if (clientReportLimit > 0 && clientReportsLeft <= 0) {
      return _buildWarningText(
        context,
        AppLocalization.getText(context)?.client_report_no_limit_warning ?? "",
        tariffName,
      );
    } else if (clientReportLimit > 0 && clientReportRatio < 0.2) {
      return _buildWarningText(
        context,
        AppLocalization.getText(context)?.client_report_limit_warning ?? "",
        tariffName,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  String? _smsWarning(BuildContext context, dynamic state) {
    final smsCount = state.ownerTariffsCheck?.data?.smsCount ?? 0;
    final usedSms = state.ownerTariffsCheck?.data?.usedSms ?? 0;
    final leftSms = smsCount - usedSms;
    final ratio = smsCount > 0 ? leftSms / smsCount : 1.0;
    final tariffName = state.ownerTariffsCheck?.data?.tariff?.name ?? '';
    String? warning;
    if (smsCount > 0 && leftSms <= 0) {
      warning = AppLocalization.getText(context)?.sms_no_limit_warning;
    } else if (smsCount > 0 && (leftSms <= 10 || ratio < 0.5)) {
      warning = AppLocalization.getText(context)?.sms_low_limit_warning;
    }
    return warning?.replaceAll(r'$tariff', tariffName);
  }

  Widget _buildWarningText(
      BuildContext context, String warning, String tariffName) {
    // Split the warning text at the placeholder
    List<String> parts = warning.split("\$tariff");

    return RichText(
      text: TextSpan(
        children: [
          // First part of the text (before tariff name)
          TextSpan(
            text: parts[0],
            style: TextStyle(
              color: context.isDark ? AppColors.redOnDark : AppColors.red,
              fontSize: 12.sp,
            ),
          ),
          // Tariff name (bold)
          TextSpan(
            text: tariffName,
            style: TextStyle(
              color: context.isDark ? AppColors.redOnDark : AppColors.red,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Second part of the text (after tariff name)
          TextSpan(
            text: parts.length > 1 ? parts[1] : "",
            style: TextStyle(
              color: context.isDark ? AppColors.redOnDark : AppColors.red,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Conditional warning banner — shows the same SMS / client-report warning
/// the page used to inline next to the SMS progress card. Hidden when the
/// builder returns an empty widget, so the layout collapses back to zero
/// height in the steady state.
class _MaybeWarningBanner extends StatelessWidget {
  const _MaybeWarningBanner({
    required this.subState,
    required this.builder,
  });

  final dynamic subState;
  final Widget Function(BuildContext, dynamic) builder;

  @override
  Widget build(BuildContext context) {
    final child = builder(context, subState);
    if (child is SizedBox) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: child,
    );
  }
}

/// Compact card showing who invited the current user.
/// Rendered on the Profile screen only when the backend returns an `inviter`
/// object on `/api/mobile/users/info` (i.e. this user signed up via someone
/// else's referral code).
class _InviterTile extends StatelessWidget {
  final Inviter inviter;

  const _InviterTile({required this.inviter});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final name = inviter.name ?? '';
    final phone = inviter.phoneNumber ?? '';
    final businessName = inviter.businessName;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22.sp,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                initial,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (l10n?.invited_by ?? 'Invited by').toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    businessName != null && businessName.isNotEmpty
                        ? '$phone · $businessName'
                        : phone,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle info banner shown to sellers above the wallet/SMS cards.
/// Tells the seller that the numbers below belong to their business
/// owner — without that hint, sellers see foreign balance values on
/// their own Profil tab and assume their account "has money."
class _OwnerAttributionBanner extends StatelessWidget {
  final String ownerName;
  const _OwnerAttributionBanner({required this.ownerName});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalization.getText(context);
    // Generated localization treats {name} as a positional Object
    // argument — call it as a method, don't do raw substitution.
    final text = l?.owner_limits_attribution(ownerName) ??
        "Quyidagi balans va limitlar biznes egasi $ownerName ga tegishli.";
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        margin: EdgeInsets.only(top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16.sp, color: context.palette.accent),
            SizedBox(width: 8.w),
            Expanded(
              child: AppText(
                text,
                fontSize: 11,
                color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact action chip for the top of the Profil page (notifications,
/// limits). Deliberately labelled — an unlabeled icon row at the top of a
/// settings page is a guessing game.
class _ProfileTopAction extends StatelessWidget {
  const _ProfileTopAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 20.sp, color: context.palette.accent),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppColors.softRed,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: AppText('$badgeCount',
                            fontSize: 9, color: Colors.white),
                      ),
                    ),
                ],
              ),
              8.w.horizontalSpace,
              Expanded(
                child: AppText(label,
                    fontSize: 12, fontWeight: FontWeight.w600, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owner-only quick actions (Mening bizneslarim / Foydalanuvchilar).
/// Foydalanuvchilar used to swap the bottom-nav to Asosiy and select the
/// Sellers sub-tab, but that tab index now shows EmployeesHomePage instead
/// (Xodimlar), so it opens the standalone SellersPage directly.
///
/// Perf: the two count-badge watches used to be inline `ref.watch` calls
/// in the menu build, so getUserShops / seller-list loads re-ran the whole
/// scroll view. Scoped here, they rebuild only this grid.
class _OwnerQuickActions extends ConsumerWidget {
  const _OwnerQuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ShopFeatures.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([features.badgesOn, features.rankingOn]),
      builder: (context, _) => QuickActionsGrid(
      actions: [
        // Nishonlarim (#711), next to the businesses and sellers.
        if (features.badgesOn.value)
          QuickAction(
            label: AppLocalization.getText(context)?.badges_title ?? 'Nishonlarim',
            icon: Icons.emoji_events_rounded,
            onTap: () => AppNavigator.push(const BadgesRoute()),
          ),
        // Reyting (#711).
        if (features.rankingOn.value)
          QuickAction(
            label: AppLocalization.getText(context)?.ranking_title ?? 'Oylik reyting',
            icon: Icons.leaderboard_rounded,
            onTap: () => AppNavigator.push(const RankingRoute()),
          ),
        QuickAction(
          label: AppLocalization.getText(context)?.my_business ??
              'Mening bizneslarim',
          icon: Icons.storefront_rounded,
          badgeCount: ref.watch(
                  homeProvider(0).select((s) => s.userShops?.data?.length)) ??
              0,
          onTap: () => AppNavigator.push(BusinessControlRoute()),
        ),
        QuickAction(
          label: AppLocalization.getText(context)?.users ?? 'Foydalanuvchilar',
          icon: Icons.groups_rounded,
          // Match the Mening bizneslarim tile by surfacing a
          // count badge — pulls from the same homeProvider state
          // the sellers page uses to render its list.
          badgeCount: ref.watch(homeProvider(0)
                  .select((s) => s.shopSellerHome?.data?.length)) ??
              0,
          onTap: () => AppNavigator.push(const SellersRoute()),
        ),
      ],
    ),
    );
  }
}

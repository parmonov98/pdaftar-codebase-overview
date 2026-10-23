
import 'package:flutter/services.dart';
import 'package:pdaftaruz/core/imports/imports.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';
import '../../../home/presantation/riverpod/provider/home_provider.dart';
import '../../../home/presantation/riverpod/state/home_state.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Profile → "Bosh ekran widgetlari".
///
/// Lists the four shortcut widgets pDaftar ships and gives owners a
/// one-tap way to pin them to the home screen.
///
/// Platform reality:
/// - **Android 8.0+** has `AppWidgetManager.requestPinAppWidget`. The
///   per-card button calls into the `pdaftar.uz/widgets` MethodChannel
///   which triggers the launcher's "Add to home screen?" dialog. On
///   pre-O Androids — or launchers that opted out — we surface a toast
///   pointing the user at the manual widget gallery.
/// - **iOS** has no API to add widgets programmatically. The card's
///   button opens a bottom sheet with three numbered steps walking the
///   user through the long-press gesture.
@RoutePage()
class HomeWidgetsPage extends ConsumerStatefulWidget {
  const HomeWidgetsPage({super.key});

  @override
  ConsumerState<HomeWidgetsPage> createState() => _HomeWidgetsPageState();
}

class _HomeWidgetsPageState extends ConsumerState<HomeWidgetsPage> {
  static const _channel = MethodChannel('pdaftar.uz/widgets');

  /// `true` on Android-with-pin-capable launcher. Determined on first
  /// build via the native channel; defaults to true on Android until
  /// the answer comes back so the buttons render in their primary
  /// state. iOS always falls into the instruction-sheet path.
  bool _pinSupported = Platform.isAndroid;
  bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _probePinSupport();
    }
  }

  Future<void> _probePinSupport() async {
    try {
      final supported =
          await _channel.invokeMethod<bool>('isPinSupported') ?? false;
      if (!mounted) return;
      setState(() => _pinSupported = supported);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pinSupported = false);
    }
  }

  Future<void> _onCardTap(BuildContext context, _WidgetCard card) async {
    if (Platform.isIOS) {
      _showIosHowToSheet(context);
      return;
    }
    if (!_pinSupported || _inFlight) return;
    setState(() => _inFlight = true);
    final l10n = AppLocalization.getText(context);
    try {
      final ok = await _channel.invokeMethod<bool>(
        'requestPin',
        {'kind': card.kind},
      );
      if (!mounted) return;
      if (ok == true) {
        AppHelpers.showSnackBarSuccess(
          message: l10n?.widget_added_success ?? 'Widget bosh ekranga qo\'shildi',
        );
      } else {
        AppHelpers.showSnackBarError(
          errorMessage:
              l10n?.widget_add_not_supported ?? 'Bu funksiya qo\'llab-quvvatlanmaydi',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppHelpers.showSnackBarError(
        errorMessage: l10n?.widget_add_failed ?? 'Widget qo\'shilmadi',
      );
    } finally {
      if (mounted) setState(() => _inFlight = false);
    }
  }

  void _showIosHowToSheet(BuildContext context) {
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      modal: const _IosHowToSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    // A pinned shortcut to something the seller may not open is a dead
    // tile on their home screen, so the card is dropped from the list
    // rather than shown and refused later.
    final canUseSalesCalc =
        ref.watch(homeProvider(0).select((s) => s.canUseSalesCalc));
    final cards = _cards(l10n)
        .where((c) => c.kind != 'sales_calc' || canUseSalesCalc)
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0, 0),
        child: AppBar(
          systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Column(
            children: [
              // Header mirrors devices_page.dart for visual consistency
              // with the other Profile sub-screens.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(1000),
                    onTap: () => AppNavigator.pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.palette.icon,
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: Container()),
                  AppText(
                    l10n?.home_screen_widgets ?? 'Bosh ekran widgetlari',
                    fontSize: 16.sp,
                  ),
                  Expanded(flex: 3, child: Container()),
                ],
              ),
              16.h.verticalSpace,
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: AppText(
                        l10n?.home_screen_widgets_subtitle ??
                            "Kirim-Chiqim, Kassa va Statistika uchun tezkor tugmalarni bosh ekraningizga qo'shing",
                        fontSize: 13.sp,
                        color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                        maxLines: 4,
                      ),
                    ),
                    16.h.verticalSpace,
                    for (final card in cards) ...[
                      _WidgetCardTile(
                        card: card,
                        ctaLabel: Platform.isIOS
                            ? (l10n?.widget_how_to_add ?? 'Qanday qo\'shish')
                            : (l10n?.widget_add_to_home_screen ??
                                "Bosh ekranga qo'shish"),
                        ctaEnabled: !_inFlight && (_pinSupported || Platform.isIOS),
                        onTap: () => _onCardTap(context, card),
                      ),
                      12.h.verticalSpace,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // `AppLocalization.getText(context)` returns a generated localization
  // class whose exact type isn't worth importing here — `dynamic` keeps
  // the helper tidy and the optional-chained `?.key` lookups still type-
  // check at the call sites.
  List<_WidgetCard> _cards(dynamic l10n) => [
        _WidgetCard(
          kind: 'quick_tx',
          title: l10n?.widget_quick_tx_title ?? 'Mijozlar +-',
          description: l10n?.widget_quick_tx_desc ??
              "Mijozga tezkor qarz yoki to'lov yozish",
          icon: Icons.swap_horiz_rounded,
          tint: const Color(0xFF6938EF),
        ),
        // Supplier-side counterpart to the client +- shortcut. Wires
        // through PendingWidgetIntent.supplierQuickTransaction; the
        // modal it opens is built in a follow-up pass — until then it
        // routes to the Ta'minotchilar home sub-tab as a safe landing.
        _WidgetCard(
          kind: 'supplier_tx',
          title: l10n?.widget_supplier_tx_title ?? "Ta'minotchi +-",
          description: l10n?.widget_supplier_tx_desc ??
              "Ta'minotchiga tezkor qarz yoki to'lov yozish",
          icon: Icons.local_shipping_rounded,
          tint: const Color(0xFFD9534F),
        ),
        _WidgetCard(
          kind: 'kassa_kirim',
          title: l10n?.widget_kassa_kirim_title ?? 'Kassaga Kirim',
          description:
              l10n?.widget_kassa_kirim_desc ?? "Kassaga kirim qo'shish",
          icon: Icons.arrow_downward_rounded,
          tint: const Color(0xFF12B76A),
        ),
        _WidgetCard(
          kind: 'kassa_chiqim',
          title: l10n?.widget_kassa_chiqim_title ?? 'Kassaga Chiqim',
          description:
              l10n?.widget_kassa_chiqim_desc ?? 'Kassadan chiqim qo\'shish',
          icon: Icons.arrow_upward_rounded,
          tint: const Color(0xFFF04438),
        ),
        // One-tap shortcut to the Sales Calculator — the calculator's
        // own client picker binds on demand; in-app tariff gates still
        // fire if a free user tries Save-as-debt.
        _WidgetCard(
          kind: 'sales_calc',
          title: l10n?.widget_sales_calc_title ?? 'Sotuv kalkulyator',
          description: l10n?.widget_sales_calc_desc ??
              'Sotuv kalkulyatorini bir bosishda ochish',
          icon: Icons.calculate_rounded,
          tint: const Color(0xFF7C3AED),
        ),
        // The standalone Statistika shortcut was removed — the live-data
        // dashboard widget below already deep-links into Statistika and
        // shows real numbers instead of just opening the page.
        // Live-data .systemMedium widget (Android: DashboardWidget;
        // iOS: DashboardWidget). Bigger footprint than the shortcuts,
        // so it gets its own card and ships under the same Android
        // requestPinAppWidget flow (Kotlin side maps "dashboard" →
        // DashboardWidget::class.java).
        _WidgetCard(
          kind: 'dashboard',
          title: l10n?.widget_dashboard_title ?? 'Mening biznesim',
          description: l10n?.widget_dashboard_desc ??
              'Mijozlar, ta\'minotchilar va kassa qisqacha ko\'rinishi',
          icon: Icons.dashboard_rounded,
          tint: const Color(0xFF6938EF),
        ),
      ];
}

class _WidgetCard {
  final String kind;
  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  const _WidgetCard({
    required this.kind,
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
  });
}

class _WidgetCardTile extends StatelessWidget {
  final _WidgetCard card;
  final String ctaLabel;
  final bool ctaEnabled;
  final VoidCallback onTap;
  const _WidgetCardTile({
    required this.card,
    required this.ctaLabel,
    required this.ctaEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  // Use a 12% alpha tint of the accent colour as the
                  // icon container. withValues() avoids the deprecated
                  // withOpacity().
                  color: card.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(card.icon, color: card.tint, size: 22.sp),
              ),
              12.w.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      card.title,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    2.h.verticalSpace,
                    AppText(
                      card.description,
                      fontSize: 12.sp,
                      color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          12.h.verticalSpace,
          // Outlined CTA — visually secondary to the page header so
          // four cards don't all scream "primary action."
          InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: ctaEnabled ? onTap : null,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: ctaEnabled
                    ? card.tint.withValues(alpha: 0.08)
                    : Theme.of(context).disabledColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: ctaEnabled
                      ? card.tint.withValues(alpha: 0.4)
                      : Theme.of(context).disabledColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Platform.isIOS
                        ? Icons.info_outline_rounded
                        : Icons.add_rounded,
                    color: ctaEnabled ? card.tint : Theme.of(context).disabledColor,
                    size: 18.sp,
                  ),
                  8.w.horizontalSpace,
                  AppText(
                    ctaLabel,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: ctaEnabled ? card.tint : Theme.of(context).disabledColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet shown on iOS — Apple offers no API to pin widgets, so
/// the best we can do is walk the user through the native gesture.
class _IosHowToSheet extends StatelessWidget {
  const _IosHowToSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final steps = [
      l10n?.widget_ios_step_1 ??
          'Bosh ekranni uzoq bosing — barcha ilovalar tebrana boshlaydi.',
      l10n?.widget_ios_step_2 ?? 'Chap yuqori burchakdagi "+" tugmasini bosing.',
      l10n?.widget_ios_step_3 ??
          'Qidiruv maydoniga "pDaftar" deb yozing va kerakli widgetni tanlab, "Widgetni qo\'shish" tugmasini bosing.',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            l10n?.widget_ios_how_to_title ?? 'iPhone\'da widget qo\'shish',
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
          16.h.verticalSpace,
          for (var i = 0; i < steps.length; i++) ...[
            _NumberedStep(number: i + 1, text: steps[i]),
            if (i < steps.length - 1) 12.h.verticalSpace,
          ],
          20.h.verticalSpace,
          CustomButtonWidget(
            title: l10n?.widget_close ?? 'Yopish',
            isLoading: false,
            onTap: () => AppNavigator.pop(),
          ),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  final int number;
  final String text;
  const _NumberedStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26.w,
          height: 26.w,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppText(
              '$number',
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: context.palette.accent,
            ),
          ),
        ),
        12.w.horizontalSpace,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: AppText(
              text,
              fontSize: 13.sp,
              maxLines: 4,
            ),
          ),
        ),
      ],
    );
  }
}

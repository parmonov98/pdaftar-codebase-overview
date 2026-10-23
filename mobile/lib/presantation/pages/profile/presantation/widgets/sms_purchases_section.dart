import 'package:pdaftaruz/constants/app_date_formatter.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/injection.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/sklad/data/trade_decimal.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// The owner's SMS purchases on "SMS tarixi" (Trello #488), one page at a
/// time for the chosen period. Kept out of the profile state on purpose:
/// nothing else in the app needs it.
class SmsPurchasesController extends ChangeNotifier {
  SmsPurchasesController({ProfileRepository? repository})
      : _repository = repository ?? inject<ProfileRepository>();

  final ProfileRepository _repository;
  final List<SmsOrder> items = [];
  int totalSms = 0;
  bool isLoading = false;
  bool hasError = false;
  bool loaded = false;
  String _period = 'current_month';
  int _page = 0;
  int _lastPage = 1;
  int _generation = 0;

  bool get hasMore => _page < _lastPage;

  Future<void> load(String period) async {
    _period = period;
    _page = 0;
    _lastPage = 1;
    items.clear();
    loaded = false;
    await _fetch(++_generation);
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    await _fetch(_generation);
  }

  Future<void> _fetch(int generation) async {
    isLoading = true;
    hasError = false;
    notifyListeners();
    final result =
        await _repository.getSmsPurchases(page: _page + 1, period: _period);
    // A newer period request replaced this one while it was in flight.
    if (generation != _generation) return;
    result.when(
      success: (data) {
        items.addAll(data.smsOrders ?? const []);
        totalSms = data.totalSms;
        _page = data.currentPage;
        _lastPage = data.lastPage;
      },
      failure: (_, __, ___) => hasError = true,
    );
    isLoading = false;
    loaded = true;
    notifyListeners();
  }
}

/// "Yuborilgan | Sotib olingan" switch under the summary card.
class SmsHistoryTabs extends StatelessWidget {
  const SmsHistoryTabs({super.key, required this.tab, required this.onChanged});

  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    Widget item(int index, String label) {
      final selected = tab == index;
      return Expanded(
        child: GestureDetector(
          key: ValueKey('sms_history_tab_$index'),
          onTap: () => onChanged(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(vertical: 9.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: AppText(label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.palette.accent),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        item(0, l10n?.sms_tab_sent ?? 'Yuborilgan'),
        item(1, l10n?.sms_tab_purchased ?? 'Sotib olingan'),
      ]),
    );
  }
}

/// One purchase: "+500 SMS", where it came from, what it cost, when.
class SmsPurchaseCard extends StatelessWidget {
  const SmsPurchaseCard({super.key, required this.order});

  final SmsOrder order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final free = (order.price ?? 0) == 0;
    final sourceLabel = switch (order.source) {
      'included' => l10n?.sms_purchase_included ?? 'Tarif bilan bepul',
      'combo' => l10n?.sms_purchase_combo ?? 'Tarif bilan birga',
      _ => l10n?.sms_purchase_single ?? 'SMS paket',
    };
    final subtitle = [
      sourceLabel,
      if ((order.tariffName ?? '').isNotEmpty) order.tariffName!
    ].join(' · ');
    final price = free
        ? (l10n?.free ?? 'Bepul')
        : '${formatTradeMoney(order.price, currencyCode: 'UZS')} UZS';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [
        Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.add_comment_outlined,
              color: AppColors.green, size: 20.sp),
        ),
        12.horizontalSpace,
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppText('+${order.smsCount ?? 0} SMS',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.green),
            2.verticalSpace,
            AppText(subtitle,
                fontSize: 12, maxLines: 1, color: Theme.of(context).hintColor),
          ]),
        ),
        8.horizontalSpace,
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          AppText(price, fontSize: 14, fontWeight: FontWeight.w600),
          2.verticalSpace,
          AppText(AppDateFormatter.format(order.createdAt, context),
              fontSize: 11, color: Theme.of(context).hintColor),
        ]),
      ]),
    );
  }
}

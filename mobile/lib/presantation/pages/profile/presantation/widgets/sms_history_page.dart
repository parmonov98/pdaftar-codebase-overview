import 'package:pdaftaruz/constants/app_date_formatter.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:lottie/lottie.dart';
import 'sms_purchases_section.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class SmsHistoryPage extends ConsumerStatefulWidget {
  const SmsHistoryPage({super.key});

  @override
  ConsumerState<SmsHistoryPage> createState() => _SmsHistoryPageState();
}

class _SmsHistoryPageState extends ConsumerState<SmsHistoryPage> {
  int _currentPage = 1;
  final int _perPage = 10;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  /// 0 = sent SMS, 1 = purchased SMS (Trello #488).
  int _tab = 0;
  String _period = 'current_month';
  final SmsPurchasesController _purchases = SmsPurchasesController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifier = ref.read(profileProvider.notifier);
      notifier.getMySmsHistory(
        page: _currentPage,
        perPage: _perPage,
        success: () {},
      );
      // Fire the summary aggregation in parallel — independent of the
      // paginated list, so we always show accurate totals even before
      // the user scrolls past the first page. Default chip is "Bu oy".
      notifier.getMySmsUsageSummary(
        isRefresh: true,
        period: 'current_month',
      );
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _purchases.dispose();
    super.dispose();
  }

  void _selectTab(int tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    if (tab == 1 && !_purchases.loaded) _purchases.load(_period);
  }

  void _selectPeriod(String period) {
    _period = period;
    // The list of sent SMS is not period-filtered; purchases are, and
    // reload only once that tab has been opened.
    if (_purchases.loaded || _tab == 1) _purchases.load(period);
  }

  void _onScroll() {
    if (_tab == 1) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        _purchases.loadMore();
      }
      return;
    }
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      final state = ref.read(profileProvider);
      final pagination = state.mySmsHistory?.pagination;
      if (pagination != null &&
          _currentPage < pagination.lastPage!) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    final notifier = ref.read(profileProvider.notifier);
    notifier.getMySmsHistory(
      page: _currentPage,
      perPage: _perPage,
      success: () {
        setState(() {
          _isLoadingMore = false;
        });
      },
    );
  }

  void _refresh() {
    if (_tab == 1) {
      _purchases.load(_period);
      return;
    }
    setState(() {
      _currentPage = 1;
    });
    final notifier = ref.read(profileProvider.notifier);
    notifier.getMySmsHistory(
      page: 1,
      perPage: _perPage,
      isRefresh: true,
      success: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final smsHistory = state.mySmsHistory;
    final smsList = smsHistory?.data ?? [];

    return Scaffold(
      appBar: AppBar(
        title: AppText(
          "${AppLocalization.getText(context)?.sms_history}",
          fontSize: 16.sp,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListenableBuilder(
          listenable: _purchases,
          builder: (context, _) {
            final header = [
              _MonthlyUsageSummary(
                tab: _tab,
                purchasedTotal: _purchases.totalSms,
                onPeriodChanged: _selectPeriod,
              ),
              SmsHistoryTabs(tab: _tab, onChanged: _selectTab),
            ];
            final List<Widget> rows;
            if (_tab == 1) {
              rows = [
                for (final order in _purchases.items)
                  SmsPurchaseCard(order: order),
                if (_purchases.isLoading)
                  _loadingRow()
                else if (_purchases.items.isEmpty)
                  _emptyRow(context, purchases: true),
              ];
            } else {
              rows = [
                if (state.isLoading && smsList.isEmpty) _loadingRow(),
                if (!state.isLoading && smsList.isEmpty)
                  _emptyRow(context, purchases: false),
                for (final sms in smsList) _buildSmsItem(context, sms),
                if (_isLoadingMore) _loadingRow(),
              ];
            }
            final all = [...header, ...rows];
            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: all.length,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              itemBuilder: (_, i) => all[i],
            );
          },
        ),
      ),
    );
  }

  Widget _loadingRow() => Center(
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: const CircularProgressIndicator.adaptive(),
        ),
      );

  Widget _emptyRow(BuildContext context, {required bool purchases}) {
    final l10n = AppLocalization.getText(context);
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(children: [
        Lottie.asset(Assets.noDataLottie, height: 160.sp, repeat: false),
        AppText(
          purchases
              ? (l10n?.sms_purchases_empty ?? "Sotib olingan SMS yo'q")
              : (l10n?.empty_purchased_sms_limit_history ?? "SMS tarixi bo'sh"),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildSmsItem(BuildContext context, sms) {
    // Parse dates
    DateTime? sentAt;
    DateTime? deliveredAt;

    try {
      if (sms.sentAt != null) {
        sentAt = DateTime.parse(sms.sentAt);
      }
      if (sms.deliveredAt != null) {
        deliveredAt = DateTime.parse(sms.deliveredAt);
      }
    } catch (e) {
      debugPrint("Error parsing date: $e");
    }

    // Get status color and localized text
    Color statusColor = Colors.grey;
    String statusText = _getLocalizedStatus(context, sms.status);
    if (sms.status == 'sent') {
      statusColor = Colors.blue;
    } else if (sms.status == 'delivered') {
      statusColor = Colors.green;
    } else if (sms.status == 'failed' || sms.status == 'error') {
      statusColor = Colors.red;
    } else if (sms.status == 'pending' || sms.status == 'waiting') {
      statusColor = Colors.orange;
    } else if (sms.status == 'scheduled') {
      statusColor = Colors.purple;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.sms,
                    color: context.palette.accent,
                    size: 24.sp,
                  ),
                ),
                16.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (sms.clientName != null)
                        AppText(
                          sms.clientName!,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (sms.phoneNumber != null) ...[
                        4.verticalSpace,
                        AppText(
                          _formatPhone(sms.phoneNumber!),
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: AppText(
                    statusText,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            if (sms.text != null) ...[
              12.verticalSpace,
              AppText(
                sms.text!,
                fontSize: 14.sp,
                maxLines: 10,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (sms.shopName != null) ...[
              8.verticalSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.store, size: 16.sp, color: Colors.grey),
                  4.horizontalSpace,
                  // Shop name flexes — long names ellipsis instead of
                  // pushing the Harajat chip off the right edge.
                  Flexible(
                    child: AppText(
                      sms.shopName!,
                      fontSize: 12.sp,
                      color: Colors.grey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sms.smsLimitSpent != null) ...[
                    8.horizontalSpace,
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: context.palette.accent.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sms_outlined,
                            size: 14.sp,
                            color: context.palette.accent,
                          ),
                          6.horizontalSpace,
                          AppText(
                            "${sms.smsLimitSpent} ${AppLocalization.getText(context)?.sms ?? "SMS"}",
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: context.palette.accent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            12.verticalSpace,
            const Divider(height: 1),
            8.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sentAt != null)
                  Row(
                    children: [
                      Icon(Icons.send, size: 14.sp, color: Colors.grey),
                      4.horizontalSpace,
                      AppText(
                        AppDateFormatter.format(sentAt, context),
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                if (deliveredAt != null)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14.sp, color: Colors.green),
                      4.horizontalSpace,
                      AppText(
                        AppDateFormatter.format(deliveredAt, context),
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatus(BuildContext context, String? status) {
    if (status == null) {
      return AppLocalization.getText(context)?.error_text ?? 'Noma\'lum';
    }

    switch (status.toLowerCase()) {
      case 'sent':
        return AppLocalization.getText(context)?.sent ?? 'Jo\'natildi';
      case 'delivered':
        return AppLocalization.getText(context)?.delivered ?? 'Yetkazildi';
      case 'failed':
        // Use error_text for shorter display, or failed_to_send_sms for full message
        return AppLocalization.getText(context)?.error_text ?? 'Xatolik';
      case 'error':
        return AppLocalization.getText(context)?.error_text ?? 'Xatolik';
      case 'pending':
        return AppLocalization.getText(context)?.status_pending ?? 'Kutilmoqda';
      case 'waiting':
        return AppLocalization.getText(context)?.waiting ?? 'Kutilmoqda';
      case 'scheduled':
        return AppLocalization.getText(context)?.scheduled ?? 'Rejalashtirilgan';
      default:
        return status;
    }
  }

  /// Aggregates `smsLimitSpent` across the loaded items by calendar
  /// month — best-effort given pagination only loads what we've asked
  /// for so far. Numbers approach the true monthly totals as the user
  /// scrolls further.
  String _formatPhone(String phoneNumber) {
    if (phoneNumber.isEmpty) return phoneNumber;
    
    // Faqat raqamlarni qoldiramiz
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // +998 ni olib tashlash
    if (digitsOnly.startsWith('998') && digitsOnly.length >= 12) {
      digitsOnly = digitsOnly.substring(3);
    }
    
    if (digitsOnly.isEmpty || digitsOnly.length < 9) return phoneNumber;
    
    // Formatlash: +998 xx xxx xx xx
    if (digitsOnly.length == 9) {
      return '+998 ${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 5)} ${digitsOnly.substring(5, 7)} ${digitsOnly.substring(7)}';
    }
    
    // Agar 9 dan ko'p raqam bo'lsa, faqat birinchi 9 tasini olamiz
    if (digitsOnly.length > 9) {
      digitsOnly = digitsOnly.substring(0, 9);
      return '+998 ${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 5)} ${digitsOnly.substring(5, 7)} ${digitsOnly.substring(7)}';
    }
    
    return phoneNumber;
  }

}

/// Two-card header at the top of the SMS history list. Reads totals
/// from `state.smsUsageSummary`, which is populated by the dedicated
/// `/users/my-sms-usage-summary` endpoint — server-aggregated, so the
/// figures don't depend on which pages of the paginated history list
/// happen to be loaded.
class _MonthlyUsageSummary extends ConsumerStatefulWidget {
  const _MonthlyUsageSummary(
      {required this.tab,
      required this.purchasedTotal,
      required this.onPeriodChanged});

  /// 1 shows the SMS bought in the period instead of the SMS used.
  final int tab;
  final int purchasedTotal;
  final ValueChanged<String> onPeriodChanged;

  @override
  ConsumerState<_MonthlyUsageSummary> createState() =>
      _MonthlyUsageSummaryState();
}

class _MonthlyUsageSummaryState extends ConsumerState<_MonthlyUsageSummary> {
  String _period = 'current_month';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(profileProvider.select((s) => s.smsUsageSummary));
    final l10n = AppLocalization.getText(context);
    final bucket = summary?.data?.bucket;
    final purchases = widget.tab == 1;
    final total = purchases ? widget.purchasedTotal : (bucket?.totalSms ?? 0);
    final jobs = purchases ? 0 : (bucket?.totalJobs ?? 0);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _chip(label: l10n?.this_month ?? 'Bu oy', value: 'current_month'),
                SizedBox(width: 6.w),
                _chip(label: l10n?.last_month ?? "O'tgan oy", value: 'previous_month'),
                SizedBox(width: 6.w),
                _chip(label: l10n?.this_year ?? 'Bu yil', value: 'this_year'),
                SizedBox(width: 6.w),
                _chip(label: l10n?.all_time ?? 'Hammasi', value: 'all_time'),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: context.palette.accent,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      purchases
                          ? (l10n?.sms_purchased_summary ?? 'sotib olingan SMS')
                          : (l10n?.sms_used_summary ?? 'ishlatilgan SMS'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Theme.of(context).hintColor,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ],
                ),
              ),
              if (jobs > 0)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    '$jobs',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(context).hintColor,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required String value}) {
    final selected = _period == value;
    return GestureDetector(
      onTap: () {
        if (_period == value) return;
        setState(() => _period = value);
        ref.read(profileProvider.notifier).getMySmsUsageSummary(
              isRefresh: true,
              period: value,
            );
        widget.onPeriodChanged(value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : context.palette.accent,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    );
  }
}

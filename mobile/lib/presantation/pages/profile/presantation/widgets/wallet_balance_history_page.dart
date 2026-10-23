import 'package:pdaftaruz/constants/app_date_formatter.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:lottie/lottie.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class WalletBalanceHistoryPage extends ConsumerStatefulWidget {
  const WalletBalanceHistoryPage({super.key});

  @override
  ConsumerState<WalletBalanceHistoryPage> createState() => _WalletBalanceHistoryPageState();
}

enum _SummaryPeriod { currentMonth, previousMonth, thisYear, allTime }

extension on _SummaryPeriod {
  String get apiValue {
    switch (this) {
      case _SummaryPeriod.currentMonth:
        return 'current_month';
      case _SummaryPeriod.previousMonth:
        return 'previous_month';
      case _SummaryPeriod.thisYear:
        return 'this_year';
      case _SummaryPeriod.allTime:
        return 'all_time';
    }
  }
}

class _WalletBalanceHistoryPageState extends ConsumerState<WalletBalanceHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;
  _SummaryPeriod _summaryPeriod = _SummaryPeriod.currentMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (!mounted) return;
      final notifier = ref.read(profileProvider.notifier);
      notifier.getWalletBalanceSummary(period: _summaryPeriod.apiValue);
      notifier.getWalletBalanceHistory(
        page: 1,
        isRefresh: true,
        success: () {
          if (!mounted) return;
          final state = ref.read(profileProvider);
          final history = state.walletBalance?.history;
          if (history != null) {
            setState(() {
              _hasMoreData = history.nextPageUrl != null && history.nextPageUrl.toString().isNotEmpty;
              _currentPage = history.currentPage ?? 1;
            });
          }
        },
      );
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = ref.read(profileProvider);
      if (!state.isBalanceHistoryLoading && _hasMoreData) {
        _loadMoreData();
      }
    }
  }

  void _loadMoreData() {
    if (!mounted) return;
    final currentState = ref.read(profileProvider);
    if (currentState.isBalanceHistoryLoading || !_hasMoreData) return;

    final notifier = ref.read(profileProvider.notifier);
    final nextPage = _currentPage + 1;

    notifier.getWalletBalanceHistory(
      page: nextPage,
      isRefresh: false,
      success: () {
        if (!mounted) return;
        final state = ref.read(profileProvider);
        final history = state.walletBalance?.history;
        if (history != null) {
          setState(() {
            _hasMoreData = history.nextPageUrl != null && history.nextPageUrl.toString().isNotEmpty;
            _currentPage = history.currentPage ?? nextPage;
          });
        } else {
          setState(() {
            _hasMoreData = false;
          });
        }
      },
    );
  }

  void _refreshData() {
    if (!mounted) return;
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });

    final notifier = ref.read(profileProvider.notifier);
    notifier.getWalletBalanceHistory(
      page: 1,
      isRefresh: true,
      success: () {
        if (!mounted) return;
        final state = ref.read(profileProvider);
        final history = state.walletBalance?.history;
        if (history != null) {
          setState(() {
            _hasMoreData = history.nextPageUrl != null && history.nextPageUrl.toString().isNotEmpty;
            _currentPage = history.currentPage ?? 1;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getTransactionIcon(String? featureType) {
    switch (featureType) {
      case "sms_purchase":
        return "📱";
      case "owner_subscription_purchase":
      case "subscription_purchase":
      case "subscription_auto_charge":
      case "seller_subscription_auto_charge":
        return "📋";
      case "business_clients_report_export":
      case "client_report_generation":
      case "supplier_report_generation":
      case "daily_summary_report_export":
        return "📊";
      case "installment_creation":
        return "💳";
      case "rental_creation":
        return "🏠";
      case "voice_message_transaction":
        return "🎤";
      case "shopping_list_share":
        return "🛒";
      default:
        return "💰";
    }
  }

  /// Localized human-readable title for each feature type the wallet can be
  /// debited/credited for. Replaces the raw English description shown in
  /// the row title — the original copy still surfaces as a subtitle so
  /// users can match a row to the specific business it belongs to.
  String _getFeatureLabel(BuildContext context, String? featureType) {
    final l10n = AppLocalization.getText(context);
    switch (featureType) {
      case 'sms_purchase':
        return l10n?.feature_sms_purchase ?? "SMS xarid";
      case 'owner_subscription_purchase':
        return l10n?.feature_owner_subscription_purchase ??
            "Asosiy tarif obuna";
      case 'subscription_purchase':
        return l10n?.feature_subscription_purchase ?? "Sotuvchi obunasi";
      case 'subscription_auto_charge':
      case 'seller_subscription_auto_charge':
        return l10n?.feature_subscription_auto_charge ??
            "Obuna avto-uzaytirish";
      case 'client_report_generation':
        return l10n?.feature_client_report_generation ??
            "Mijoz hisoboti";
      case 'supplier_report_generation':
        return l10n?.feature_supplier_report_generation ??
            "Ta'minotchi hisoboti";
      case 'business_clients_report_export':
        return l10n?.feature_business_clients_report_export ??
            "Biznes hisoboti";
      case 'daily_summary_report_export':
        return l10n?.feature_daily_summary_report_export ??
            "Kunlik xulosa hisoboti";
      case 'installment_creation':
        return l10n?.feature_installment_creation ?? "Bo'lib to'lash";
      case 'rental_creation':
        return l10n?.feature_rental_creation ?? "Ijara";
      case 'voice_message_transaction':
        return l10n?.feature_voice_message ?? "Ovozli xabar";
      case 'shopping_list_share':
        return l10n?.feature_shopping_list_share ??
            "Bozorlik ro'yxat ulashish";
      default:
        return l10n?.transaction ?? "Tranzaksiya";
    }
  }

  /// Pulls the trailing context (usually a business name) out of the
  /// backend's `"<feature> - <name>"` description format. Falls back to the
  /// full description when there's no separator. Returns null when there
  /// is nothing extra to show.
  String? _extractContext(String? description) {
    if (description == null || description.isEmpty) return null;
    final dashIndex = description.indexOf(' - ');
    if (dashIndex == -1) return null;
    final tail = description.substring(dashIndex + 3).trim();
    return tail.isEmpty ? null : tail;
  }

  Color _getTransactionColor(String? type, String? amount) {
    if (type == "spent") {
      return AppColors.errorColor;
    }

    // Check if amount is negative
    final amountValue = double.tryParse(amount ?? "0") ?? 0;
    if (amountValue < 0) {
      return AppColors.errorColor;
    }

    return AppColors.green;
  }

  Widget _periodChip({
    required String label,
    required _SummaryPeriod period,
  }) {
    final selected = _summaryPeriod == period;
    return GestureDetector(
      onTap: () {
        if (_summaryPeriod == period) return;
        setState(() => _summaryPeriod = period);
        ref
            .read(profileProvider.notifier)
            .getWalletBalanceSummary(period: period.apiValue);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor
              : AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.center,
        child: AppText(
          label,
          fontSize: 12.sp,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? Colors.white : context.palette.accent,
        ),
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required double value,
    bool bold = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: AppText(
            label,
            fontSize: bold ? 13.sp : 12.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: bold ? null : Colors.grey,
          ),
        ),
        AppText(
          "${AppMoneyFormatter.longFormatDouble(value)} UZS",
          fontSize: bold ? 14.sp : 12.sp,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: context.isDark ? AppColors.redOnDark : AppColors.errorColor,
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(BuildContext context) {
    final l10n = AppLocalization.getText(context);
    final state = ref.watch(profileProvider);
    final summary = state.walletBalanceSummary;
    final isSummaryLoading = state.isWalletBalanceSummaryLoading;
    final totalSpent = summary?.totalSpent ?? 0;
    final rawEntries = summary?.byFeature ?? const [];

    // Multiple feature_type codes can collapse to the same localized label
    // (e.g. owner_subscription_purchase + subscription_purchase → "Tarif
    // obunasi"). Merge them so the breakdown shows one row per label.
    final mergedByLabel = <String, ({String featureKey, double total})>{};
    for (final e in rawEntries) {
      final label = _getFeatureLabel(context, e.featureType);
      final existing = mergedByLabel[label];
      mergedByLabel[label] = (
        featureKey: existing?.featureKey ?? (e.featureType ?? 'other'),
        total: (existing?.total ?? 0) + e.total,
      );
    }
    final entries = mergedByLabel.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      padding: EdgeInsets.all(14.sp),
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
          AppText(
            l10n?.wallet_history_summary_title ??
                "Funksiyalar bo'yicha xarajat",
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          10.verticalSpace,
          SizedBox(
            height: 32.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _periodChip(
                  label: l10n?.this_month ?? "Bu oy",
                  period: _SummaryPeriod.currentMonth,
                ),
                6.horizontalSpace,
                _periodChip(
                  label: l10n?.last_month ?? "O'tgan oy",
                  period: _SummaryPeriod.previousMonth,
                ),
                6.horizontalSpace,
                _periodChip(
                  label: l10n?.this_year ?? "Bu yil",
                  period: _SummaryPeriod.thisYear,
                ),
                6.horizontalSpace,
                _periodChip(
                  label: l10n?.all_time ?? "Hammasi",
                  period: _SummaryPeriod.allTime,
                ),
              ],
            ),
          ),
          10.verticalSpace,
          _summaryRow(
            label: l10n?.wallet_history_total_spent ?? "Jami sarflandi",
            value: totalSpent,
            bold: true,
          ),
          if (entries.isNotEmpty) ...[
            8.verticalSpace,
            Container(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.15),
            ),
            10.verticalSpace,
          ] else
            12.verticalSpace,
          if (isSummaryLoading && entries.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.palette.accent,
                  ),
                ),
              ),
            )
          else
            ...entries.map((entry) {
              final label = entry.key;
              final total = entry.value.total;
              final featureKey = entry.value.featureKey;
              final pct = totalSpent == 0 ? 0.0 : total / totalSpent;
              return Padding(
                padding: EdgeInsets.only(bottom: 8.sp),
                child: Row(
                  children: [
                    AppText(
                      _getTransactionIcon(featureKey),
                      fontSize: 16.sp,
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            label,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          4.verticalSpace,
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3.r),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor:
                                  AppColors.errorColor.withValues(alpha: 0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    10.horizontalSpace,
                    AppText(
                      "${AppMoneyFormatter.longFormatDouble(total)} UZS",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: context.isDark ? AppColors.redOnDark : AppColors.errorColor,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final history = state.walletBalance?.history;
    final historyData = history?.data ?? [];
    final isLoading = state.isLoading && historyData.isEmpty;
    final isPaginationLoading = state.isBalanceHistoryLoading;

    return Scaffold(
      appBar: AppBar(
        title: AppText(
          AppLocalization.getText(context)?.balance_history ?? "Balans tarixi",
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: context.palette.accent,
          ),
        )
            : historyData.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                Assets.noDataLottie,
                height: 200.sp,
                repeat: false,
              ),
              16.verticalSpace,
              Padding(
                padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
                child: AppText(

                  AppLocalization.getText(context)?.empty_balance_history ?? "Balans tarixi bo'sh",
                  fontSize: 16.sp,
                  maxLines: 10,
                  textAlign: TextAlign.center,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            itemCount: historyData.length + 1 + (isPaginationLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildSummaryHeader(context);
              }
              final dataIndex = index - 1;
              if (dataIndex == historyData.length) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: CircularProgressIndicator(
                      color: context.palette.accent,
                    ),
                  ),
                );
              }

              final item = historyData[dataIndex];
              final amountValue = double.tryParse(item.amount ?? "0") ?? 0;
              final isNegative = amountValue < 0;
              final transactionColor = _getTransactionColor(item.type, item.amount);

              return Container(
                margin: EdgeInsets.only(bottom: 12.sp),
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
                child: Padding(
                  padding: EdgeInsets.all(14.sp),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 44.sp,
                        height: 44.sp,
                        decoration: BoxDecoration(
                          color: transactionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        alignment: Alignment.center,
                        child: AppText(
                          _getTransactionIcon(item.featureType),
                          fontSize: 20.sp,
                        ),
                      ),
                      12.horizontalSpace,

                          // Middle section - Localized title + raw context
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  _getFeatureLabel(context, item.featureType),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_extractContext(item.description) != null) ...[
                                  2.verticalSpace,
                                  AppText(
                                    _extractContext(item.description)!,
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                            6.verticalSpace,

                            // Status badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.sp,
                                vertical: 4.sp,
                              ),
                              decoration: BoxDecoration(
                                color: isNegative
                                    ? AppColors.errorColor.withValues(alpha: 0.1)
                                    : AppColors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: AppText(
                                isNegative
                                    ? (AppLocalization.getText(context)?.spent ?? "Sarflandi")
                                    : "Qabul qilindi",
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: transactionColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            4.verticalSpace,

                            // Date
                            AppText(
                              AppDateFormatter.format(item.createdAt, context),
                              fontSize: 11.sp,
                              color: Colors.grey,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      12.horizontalSpace,

                      // Right section - Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppText(
                            "${isNegative ? "" : "+"}${AppMoneyFormatter.longFormatDouble(amountValue.abs())}",
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: transactionColor,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          2.verticalSpace,
                          AppText(
                            "UZS",
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
}
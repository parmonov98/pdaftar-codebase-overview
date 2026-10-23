import 'dart:async';

import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/clarity/clarity_analytics.dart';
import 'package:pdaftaruz/service/clarity/clarity_events.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';
import 'package:pdaftaruz/presantation/global_widgets/app_shimmer_widget.dart';
import 'package:pdaftaruz/presantation/pages/applications/presantation/widgets/payment_type_widget.dart';
import 'package:pdaftaruz/presantation/pages/applications/data/owner_tariffs_response.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../../../../global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class SmsTariffPage extends ConsumerStatefulWidget {
  const SmsTariffPage({super.key});

  @override
  ConsumerState<SmsTariffPage> createState() => _SmsTariffPageState();
}

class _SmsTariffPageState extends ConsumerState<SmsTariffPage> {
  Timer? _priceDebounce;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final state = ref.watch(profileProvider);
      final notifier = ref.read(profileProvider.notifier);
      if (state.smsTariffs == null) {
        ref.read(profileProvider.notifier).getSMSTariffs(
          success: () {
            // Tariflar yuklangandan keyin "Free 50" (id: 13) ni tanlash, agar topilmasa sms_count >= 10 bo'lgan birinchi tarifni
            final updatedState = ref.read(profileProvider);
            if (updatedState.smsTariffs?.smsTariffs?.isNotEmpty == true &&
                updatedState.smsTariffID == 0) {
              // Avval "Free 50" (id: 13) ni qidirish
              try {
                updatedState.smsTariffs!.smsTariffs!
                    .firstWhere((tariff) => tariff.id == 13);
                notifier.changeSMSTariff(13);
              } catch (e) {
                // Agar "Free 50" topilmasa, sms_count >= 10 bo'lgan birinchi tarifni tanlash
                final filteredTariffs = updatedState.smsTariffs!.smsTariffs!
                    .where((tariff) => (tariff.smsCount ?? 0) >= 10)
                    .toList();
                if (filteredTariffs.isNotEmpty) {
                  final firstTariffId = filteredTariffs.first.id ?? 0;
                  notifier.changeSMSTariff(firstTariffId);
                }
              }
            }
          },
        );
      } else {
        // Agar tariflar allaqachon yuklangan bo'lsa va tanlangan tarif yo'q bo'lsa, "Free 50" (id: 13) ni tanlash
        if (state.smsTariffs?.smsTariffs?.isNotEmpty == true &&
            state.smsTariffID == 0) {
          // Avval "Free 50" (id: 13) ni qidirish
          try {
            state.smsTariffs!.smsTariffs!
                .firstWhere((tariff) => tariff.id == 13);
            notifier.changeSMSTariff(13);
          } catch (e) {
            // Agar "Free 50" topilmasa, sms_count >= 10 bo'lgan birinchi tarifni tanlash
            final filteredTariffs = state.smsTariffs!.smsTariffs!
                .where((tariff) => (tariff.smsCount ?? 0) >= 10)
                .toList();
            if (filteredTariffs.isNotEmpty) {
              final firstTariffId = filteredTariffs.first.id ?? 0;
              notifier.changeSMSTariff(firstTariffId);
            }
          }
        }
      }
      // Load owner tariffs if not loaded. One-shot read — initState
      // shouldn't anchor a watch subscription.
      final ownerTariffs = ref.read(homeProvider(0)).ownerTariffs;
      if (ownerTariffs == null) {
        ref.read(homeProvider(0).notifier).getOwnerTariffs();
      }
      // SMS funnel: user reached the SMS tariff page (the F5 entry).
      ClarityAnalytics.instance.tag('tariff_page', 'sms');
      ClarityAnalytics.instance.event(ClarityEvents.smsTariffPageViewed);
    });
    super.initState();
  }

  @override
  void dispose() {
    _priceDebounce?.cancel();
    super.dispose();
  }

  void _schedulePriceLookup(String rawValue) {
    _priceDebounce?.cancel();
    final notifier = ref.read(profileProvider.notifier);
    notifier.clearSmsCountPrice();
    final quantity = int.tryParse(rawValue.replaceAll(' ', ''));
    if (quantity == null || quantity < 10) return;
    _priceDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      notifier.getSmsCountPrice();
    });
  }

  void _clearCustomQuantity() {
    _priceDebounce?.cancel();
    final notifier = ref.read(profileProvider.notifier);
    notifier.smsCountController.clear();
    notifier.clearSmsCountPrice();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final homeState = ref.watch(homeProvider(0).select((s) => (
          ownerTariffs: s.ownerTariffs,
          ownerTariffsCheck: s.ownerTariffsCheck,
        )));
    
    // Default SMS option ni tanlash - "Free 50" (id: 13) ni tanlash, agar topilmasa sms_count >= 10 bo'lgan birinchi tarifni
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.smsTariffs?.smsTariffs?.isNotEmpty == true &&
          state.smsTariffID == 0 &&
          notifier.smsCountController.text.isEmpty) {
        // Avval "Free 50" (id: 13) ni qidirish
        try {
          state.smsTariffs!.smsTariffs!
              .firstWhere((tariff) => tariff.id == 13);
          notifier.changeSMSTariff(13);
        } catch (e) {
          // Agar "Free 50" topilmasa, sms_count >= 10 bo'lgan birinchi tarifni tanlash
          final filteredTariffs = state.smsTariffs!.smsTariffs!
              .where((tariff) => (tariff.smsCount ?? 0) >= 10)
              .toList();
          if (filteredTariffs.isNotEmpty) {
            final firstTariffId = filteredTariffs.first.id ?? 0;
            notifier.changeSMSTariff(firstTariffId);
          }
        }
      }
    });

    // Calculate expiry date from createdAt + 1 month
    String? expiryDateFormatted;
    final createdAt = homeState.ownerTariffsCheck?.data?.createdAt;
    if (createdAt != null) {
      // Properly handle month overflow (e.g., December -> January of next year)
      int year = createdAt.year;
      int month = createdAt.month + 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      // Handle day overflow (e.g., Jan 31 -> Feb 28/29)
      int day = createdAt.day;
      final daysInMonth =
          DateTime(year, month + 1, 0).day; // Get last day of target month
      if (day > daysInMonth) {
        day = daysInMonth;
      }
      final expiryDate = DateTime(year, month, day);
      expiryDateFormatted =
          '${expiryDate.day.toString().padLeft(2, '0')}.${expiryDate.month.toString().padLeft(2, '0')}.${expiryDate.year}';
    }

    // Build alert text based on tariff type
    String? alertText;
    if (expiryDateFormatted != null) {
      final isFreeTariff =
          homeState.ownerTariffsCheck?.data?.tariff?.isFree == true;
      final tariffName =
          homeState.ownerTariffsCheck?.data?.tariff?.name ?? 'Bepul';
      final line1 = AppLocalization.getText(context)
              ?.sms_subscription_expiry_alert(
                  expiryDateFormatted, tariffName) ??
          '';
      final line2 = AppLocalization.getText(context)
              ?.sms_free_tariff_unused_not_carried ??
          "Bepul tariffda ishlatilmagan yangi oyga o'tkazilmaydi.";
      final line3 = AppLocalization.getText(context)
              ?.paid_tariff_sms_limit_carried_over ??
          "Pullik tarifflarda sms limitlar o'tkaziladi.";

      // Bepul tarif: 3 qator (limitlar sanada yangilanadi + ishlatilmagan o'tkazilmaydi + pullikda o'tkaziladi)
      // Pullik tarif: 2 qator (limitlar sanada yangilanadi + pullikda o'tkaziladi)
      String alertTextPart;
      if (isFreeTariff) {
        alertTextPart = '$line1\n$line2';
      } else {
        alertTextPart = line1;
      }
      alertText = '$alertTextPart\n$line3';
    }
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          "${AppLocalization.getText(context)?.sms_package}",
          fontSize: 16.sp,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextField(
                  controller: notifier.smsCountController,
                  title: "${AppLocalization.getText(context)?.how_much_SMS}",
                  labelText:
                      "${AppLocalization.getText(context)?.enter_number}",
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    final formatted = value?.formatWithThousandsSeparator;
                    if (value != formatted) {
                      notifier.smsCountController.value =
                          notifier.smsCountController.value.copyWith(
                        text: formatted,
                        selection: TextSelection.collapsed(
                            offset: formatted?.length ?? 0),
                      );
                    }
                    // Agar text kiritilsa va tariff tanlangan bo'lsa, tariffni tozala
                    if (value!.isNotEmpty && state.smsTariffID != 0) {
                      notifier
                          .changeSMSTariff(0); // yoki setSelectedTariff(null)
                    }
                    _schedulePriceLookup(value);
                  },
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: notifier.smsCountController,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                CupertinoIcons.clear_circled,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed: () {
                                _clearCustomQuantity();
                              },
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: notifier.smsCountController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    final total = state.smsCountPrice?.totalPrice;
                    return Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            AppLocalization.getText(context)
                                    ?.sms_custom_total ??
                                '',
                            fontSize: 13.sp,
                          ),
                          AppText(
                            total == null
                                ? '—'
                                : '${AppMoneyFormatter.longFormatString(total.toString())} UZS',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                12.verticalSpace,
                // Alert text for subscription expiry
                if (expiryDateFormatted != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 12.sp),
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: context.palette.accent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.info,
                              color: context.palette.accent,
                              size: 20.sp,
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: AppText(
                                maxLines: 5,
                                alertText ?? '',
                                fontSize: 11.sp,
                                color: context.palette.accent,
                              ),
                            ),
                          ],
                        ),
                        // AppText(
                        //   fontSize: 11.sp,
                        //   color: AppColors.primaryColor,
                        // ),
                      ],
                    ),
                  ),
                state.isLoading
                    ? CustomShimmerEffect(
                        isLoading: state.isLoading,
                        leaf: false,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: 5,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.sp),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.sp),
                                child: Column(
                                  spacing: 8.sp,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: AppText(
                                            "smsTariffs?.name ?? " "",
                                          ),
                                        ),
                                        RadioGroup<bool>(
                                          groupValue: false,
                                          onChanged: (value) {},
                                          child: const CupertinoRadio(
                                            value: false,
                                            activeColor:
                                                AppColors.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const AppText(
                                      "SHIMMER TEMPLATE SMS",
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.sp, vertical: 6.sp),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor
                                            .withAlpha(350),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: const AppText(
                                        "SHIMMER TEMPLATE UZS",
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ))
                    : state.smsTariffs?.smsTariffs?.isEmpty ?? false
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: Center(
                              child: Lottie.asset(Assets.noDataLottie,
                                  height: 200, repeat: false),
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              // Faqat sms_count >= 10 bo'lgan tariflarni ko'rsatish (Free 1 kabi 10 dan kichik tariflarni yashirish)
                              final filteredTariffs = (state.smsTariffs?.smsTariffs ?? [])
                                  .where((tariff) => (tariff.smsCount ?? 0) >= 10)
                                  .toList();
                              
                              if (filteredTariffs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  child: Center(
                                    child: Lottie.asset(Assets.noDataLottie,
                                        height: 200, repeat: false),
                                  ),
                                );
                              }
                              
                              return Container(
                                margin: EdgeInsets.symmetric(vertical: 10.sp),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredTariffs.length,
                                  itemBuilder: (context, index) {
                                    final smsTariffs = filteredTariffs[index];

                                final isTextEntered =
                                    notifier.smsCountController.text.isNotEmpty;
                                final isSelected =
                                    state.smsTariffID == smsTariffs.id;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 12.sp),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: isSelected && !isTextEntered
                                          ? context.palette.accent
                                          : AppColors.transparent,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16.r),
                                    onTap: () {
                                      // Agar tariff tanlansa, textni tozala
                                      if (isTextEntered) {
                                        notifier.smsCountController.clear();
                                      }
                                      notifier
                                          .changeSMSTariff(smsTariffs.id ?? 0);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(16.sp),
                                      child: Column(
                                        spacing: 8.sp,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: AppText(
                                                  smsTariffs.name ?? "",
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: context.palette.accent,
                                                ),
                                              ),
                                              RadioGroup<int>(
                                                groupValue: isTextEntered
                                                    ? null
                                                    : state.smsTariffID,
                                                onChanged: (value) {
                                                  // Agar tariff tanlansa, textni tozala
                                                  if (isTextEntered) {
                                                    notifier.smsCountController
                                                        .clear();
                                                  }
                                                  notifier.changeSMSTariff(
                                                      value ?? 0);
                                                },
                                                child: CupertinoRadio<int>(
                                                  value: smsTariffs.id ?? 0,
                                                  activeColor:
                                                      AppColors.primaryColor,
                                                  inactiveColor:
                                                      AppColors.disabledColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          AppText(
                                            "${AppLocalization.getText(context)?.sms_limit}: ${smsTariffs.smsCount ?? 0} SMS",
                                            fontSize: 14.sp,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.sp,
                                                vertical: 6.sp),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryColor
                                                  .withAlpha(350),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                AppText(
                                                  "${AppLocalization.getText(context)?.price}: ${AppMoneyFormatter.longFormatString(smsTariffs.price.toString())} UZS",
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                if (smsTariffs.smsRate != null)
                                                  AppText(
                                                    "${AppLocalization.getText(context)?.price_sms ?? "SMS narxi"}: ${AppMoneyFormatter.longFormatDouble(smsTariffs.smsRate)} ${AppLocalization.getText(context)?.som ?? "so'm"}",
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                                ),
                              );
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Alert text for tariff upgrade recommendation
            Builder(
              builder: (context) {
                final currentHomeState =
                    ref.watch(homeProvider(0).select((s) => (
                          ownerTariffsCheck: s.ownerTariffsCheck,
                          ownerTariffs: s.ownerTariffs,
                        )));
                final currentTariff =
                    currentHomeState.ownerTariffsCheck?.data?.tariff;
                final ownerTariffs = currentHomeState.ownerTariffs?.data;

                // Find next higher (recommended) tariff
                String? alertText;
                String? recommendedTariffName;
                String? recommendedSuffixText;
                if (currentTariff != null && ownerTariffs != null) {
                  final currentTariffType = currentTariff.type?.toLowerCase();
                  List<Tariff>? tariffsOfSameType;

                  // Get tariffs of the same type as current tariff
                  if (currentTariffType == 'monthly') {
                    tariffsOfSameType = ownerTariffs.monthly;
                  } else if (currentTariffType == 'quarterly') {
                    tariffsOfSameType = ownerTariffs.quarterly;
                  } else if (currentTariffType == 'yearly') {
                    tariffsOfSameType = ownerTariffs.yearly;
                  }

                  if (tariffsOfSameType != null &&
                      tariffsOfSameType.isNotEmpty) {
                    // Sort tariffs by price (uzsPrice)
                    final sortedTariffs = List<Tariff>.from(tariffsOfSameType)
                      ..sort((a, b) {
                        final priceA = a.uzsPrice ?? 0;
                        final priceB = b.uzsPrice ?? 0;
                        return priceA.compareTo(priceB);
                      });

                    // Find current tariff index
                    final currentTariffId = currentTariff.id;
                    final currentIndex = sortedTariffs
                        .indexWhere((t) => t.id == currentTariffId);

                    // Find next higher tariff
                    if (currentIndex >= 0 &&
                        currentIndex < sortedTariffs.length - 1) {
                      final nextTariff = sortedTariffs[currentIndex + 1];
                      final smsRate = nextTariff.smsRate;
                      if (smsRate != null) {
                        final formattedSmsRate =
                            AppMoneyFormatter.longFormatDouble(smsRate);
                        // Matnni ikki qismga ajratamiz: tarif nomi (klik qilinadigan)
                        // va qolgan ogohlantirish matni (oddiy text)
                        recommendedTariffName = nextTariff.name;
                        recommendedSuffixText =
                            " tariffga o'tsangiz $formattedSmsRate ${AppLocalization.getText(context)?.som ?? "so'm"}dan olsangiz bo'ladi.";
                        alertText =
                            "$recommendedTariffName$recommendedSuffixText";
                      }
                    }
                  }
                }

                // Don't show alert if user has the highest tariff
                if (alertText == null) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin:
                      EdgeInsets.only(bottom: 8.sp, left: 12.sp, right: 12.sp),
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    // Success rang uslubi
                    color: AppColors.successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.successColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info,
                        color: AppColors.successColor,
                        size: 20.sp,
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: RichText(
                          maxLines: 3,
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 11.sp,
                                  color: AppColors.successColor,
                                ),
                            children: [
                              if (recommendedTariffName != null)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Tavsiya etilgan tarifga bosilganda OwnerTariffPage ga o'tish
                                      MixpanelAnalyticsService.instance.track(
                                          MixpanelEvents.upgradeTariffClicked, {
                                        'Source': 'sms_tariff',
                                      });
                                      AppNavigator.push(
                                        const OwnerTariffRoute(),
                                      );
                                    },
                                      child: Text(
                                        recommendedTariffName,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.successColor,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.successColor,
                                        ),
                                      ),
                                  ),
                                ),
                              TextSpan(
                                text: recommendedSuffixText ?? alertText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Tanlangan tarif nomi (Xarid qilish tugmasi ustida)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: notifier.smsCountController,
            builder: (context, textValue, child) {
              // Disabled logic: Agar text va tariff ikkalasi ham bo'sh bo'lsa disabled
              final currentState = ref.watch(profileProvider);
              final buttonDisabled = currentState.smsTariffID == 0 && textValue.text.isEmpty;

              return CustomButtonWidget(
                title: "${AppLocalization.getText(context)?.buy}",
                disabled: buttonDisabled || currentState.isLoading,
                isLoading:
                    currentState.isLoading && textValue.text.isNotEmpty,
                onTap: () async {
                if (notifier.smsCountController.text.isNotEmpty) {
                  _priceDebounce?.cancel();
                  final smsCount = int.tryParse(
                      notifier.smsCountController.text.replaceAll(" ", ""));
                  if (smsCount != null && smsCount < 10) {
                    AppHelpers.showSnackBarError(
                        errorMessage:
                            "${AppLocalization.getText(context)?.min_sms_qty}");
                    return;
                  }
                  if (smsCount == null) {
                    return;
                  }
                  final priceReady = notifier.hasSmsPriceForQuantity(smsCount)
                      ? true
                      : await notifier.getSmsCountPrice();
                  if (!context.mounted || !priceReady) {
                    return;
                  }
                  final currentCount = int.tryParse(notifier
                      .smsCountController.text
                      .replaceAll(" ", ""));
                  if (currentCount != smsCount ||
                      !notifier.hasSmsPriceForQuantity(smsCount)) {
                    return;
                  }
                }
                AppHelpers.showCustomModalBottomSheet(
                    context: context,
                    modal: Consumer(
                      builder:
                          (BuildContext context, WidgetRef ref, Widget? child) {
                        final state = ref.watch(profileProvider);
                        final notifier = ref.read(profileProvider.notifier);
                        final selectedTariff = state.smsTariffID != 0
                            ? state.smsTariffs?.smsTariffs?.firstWhere(
                                (tariff) => tariff.id == state.smsTariffID)
                            : null;
                        final totalPrice =
                            int.tryParse("${state.smsCountPrice?.totalPrice}");
                        final referralBalance = int.tryParse(
                            LocalStorage.instance.getReferralBalance());
                        // Talab qilinadigan summa (manual kiritilgan bo'lsa totalPrice, aks holda tanlangan tarif narxi)
                        final int requiredAmount =
                            notifier.smsCountController.text.isNotEmpty
                                ? (totalPrice ?? 0)
                                : (selectedTariff?.price ?? 0);
                        return CustomShimmerEffect(
                          isLoading: state.isBalanceHistoryLoading,
                          leaf: false,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 15.0.sp),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                    "${AppLocalization.getText(context)?.buy_SMS}"),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    10.h.verticalSpace,
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        notifier.smsCountController.text
                                                    .isEmpty &&
                                                selectedTariff != null
                                            ? Column(
                                                children: [
                                                  AppText(
                                                    "${selectedTariff.price} UZS",
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.w600,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  if (selectedTariff.smsRate != null)
                                                    AppText(
                                                      "${AppLocalization.getText(context)?.price_sms ?? "SMS narxi"}: ${AppMoneyFormatter.longFormatDouble(selectedTariff.smsRate)} ${AppLocalization.getText(context)?.som ?? "so'm"}",
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w500,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                ],
                                              )
                                            : Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      AppText(
                                                          "${AppLocalization.getText(context)?.sms_quantity}"),
                                                      AppText(notifier
                                                          .smsCountController
                                                          .text),
                                                    ],
                                                  ),
                                                  10.h.verticalSpace,
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      AppText(
                                                          "${AppLocalization.getText(context)?.price}"),
                                                      // Guard: while the
                                                      // count-price lookup is
                                                      // in flight or failed,
                                                      // show a placeholder —
                                                      // this used to print a
                                                      // literal "null UZS"
                                                      // (Trello #150).
                                                      AppText(totalPrice != null
                                                          ? "${AppMoneyFormatter.longFormatString(totalPrice.toString())} UZS"
                                                          : "—"),
                                                    ],
                                                  ),
                                                  if (selectedTariff?.smsRate != null) ...[
                                                    10.h.verticalSpace,
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        AppText(
                                                            AppLocalization.getText(context)?.price_sms ?? "SMS narxi"),
                                                        AppText(
                                                            "${AppMoneyFormatter.longFormatDouble(selectedTariff?.smsRate)} ${AppLocalization.getText(context)?.som ?? "so'm"}"),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                        10.h.verticalSpace,
                                        PaymentTypeWidget(
                                            service: "wallet",
                                            serviceLogo:
                                                Assets.walletBalanceSvg,
                                            paymentService:
                                                state.paymentService,
                                            onTap: () {
                                              notifier.changePaymentService(
                                                  value: "wallet");
                                            }),
                                        4.verticalSpace,
                                        state.paymentService == "wallet" &&
                                                ((state.walletBalance
                                                            ?.totalWalletBalance ??
                                                        0) <
                                                    requiredAmount)
                                            ? Row(
                                                spacing: 4,
                                                children: [
                                                  const CustomSvgWidgetAsset(
                                                    Assets.infoSvg,
                                                    color: AppColors.errorColor,
                                                  ),
                                                  AppText(
                                                    "${AppLocalization.getText(context)?.not_enough_money_in_balance}",
                                                    color: context.isDark ? AppColors.redOnDark : AppColors.errorColor,
                                                    maxLines: 2,
                                                    fontSize: 10.sp,
                                                  ),
                                                ],
                                              )
                                            : const SizedBox.shrink(),
                                        15.h.verticalSpace,
                                        PaymentTypeWidget(
                                            service: "referal_balance",
                                            serviceLogo: Assets.walletSvg,
                                            paymentService:
                                                state.paymentService,
                                            onTap: () {
                                              notifier.changePaymentService(
                                                  value: "referal_balance");
                                            }),
                                        4.verticalSpace,
                                        state.paymentService ==
                                                "referal_balance"
                                            ? ((referralBalance ?? 0) <
                                                    requiredAmount)
                                                ? Row(
                                                    spacing: 4,
                                                    children: [
                                                      const CustomSvgWidgetAsset(
                                                        Assets.infoSvg,
                                                        color: AppColors
                                                            .errorColor,
                                                      ),
                                                      AppText(
                                                        "${AppLocalization.getText(context)?.not_enough_money_in_referral_balance}",
                                                        color: AppColors
                                                            .errorColor,
                                                        fontSize: 10.sp,
                                                      ),
                                                    ],
                                                  )
                                                : 0.verticalSpace
                                            : 0.verticalSpace,
                                        14.sp.verticalSpace,
                                      ],
                                    ),
                                    CustomButtonWidget(
                                      title:
                                          "${AppLocalization.getText(context)?.buy}",
                                      isLoading: state.isLoading,
                                      disabled: state.paymentService.isEmpty ||
                                          (state.paymentService ==
                                                  "referal_balance"
                                              ? ((referralBalance ?? 0) <
                                                  requiredAmount)
                                              : (state.paymentService ==
                                                      "wallet"
                                                  ? ((state.walletBalance
                                                              ?.totalWalletBalance ??
                                                          0) <
                                                      requiredAmount)
                                                  : false)),
                                      onTap: () async {
                                        // SMS packages are paid from the wallet /
                                        // referral balance (internal credit) — no
                                        // external payment, so this stays in-app.
                                        await notifier.buySMSTariffOrder(
                                            userID:
                                                LocalStorage.instance.getID(),
                                            smsTariffID: notifier
                                                    .smsCountController
                                                    .text
                                                    .isNotEmpty
                                                ? state
                                                    .smsCountPrice?.tariff?.id
                                                : state.smsTariffID,
                                            paySys: state.paymentService,
                                            smsCount: int.tryParse(notifier
                                                .smsCountController.text
                                                .replaceAll(" ", '')),
                                            context: context,
                                            success: () {
                                              // Faqat referal balance bilan to'lashda balance history'ni yangilash
                                              notifier.getBalanceHistory();
                                              ref
                                                  .read(
                                                      homeProvider(0).notifier)
                                                  .checkOwnerTariffs();

                                              try {
                                                MixpanelAnalyticsService.instance.track(MixpanelEvents.smsTariffSelected, {
                                                  'tariff_id': state.smsTariffID,
                                                  'payment_service': state.paymentService,
                                                });
                                              } catch (_) {}

                                              AppNavigator.pop();
                                              // Success snackbar ko'rsatish
                                              AppHelpers.showSnackBarSuccess(
                                                  message: AppLocalization
                                                              .getText(context)
                                                          ?.sms_successfully_purchased ??
                                                      'SMS muvaffaqiyatli sotib olindi!');
                                            });
                                      },
                                    ),
                                    18.sp.verticalSpace,
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                );
                },
              );}
            ),)
          ],
        ),
      ),
    );
  }



}

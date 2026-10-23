import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';
import 'package:pdaftaruz/presantation/global_widgets/app_shimmer_widget.dart';
import 'package:pdaftaruz/presantation/global_widgets/money_formatter.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/balance_history_page.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/invited_users_through_referral_widget.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/paid_users_through_referral_widget.dart';
import 'referral_stand_button.dart';
import 'referral_rewards_section.dart';
import '../riverpod/referral_rewards_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'dart:math' as math;

import '../../../../global_widgets/client_card_widget.dart';
import '../../../auth/widgets/custom_textfield_widget/search_textfield/app_search_textfield.dart';
import '../../../client_contact/data/app_contact.dart';
import '../../../client_contact/presantation/riverpod/provider/contact_page_provider.dart';
import '../../../client_contact/presantation/widgets/add_contact_widget/riverpod/provider/add_contact_modal_provider.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

@RoutePage()
class UserReferralCodePage extends ConsumerStatefulWidget {
  const UserReferralCodePage({super.key});

  @override
  ConsumerState<UserReferralCodePage> createState() => _UserReferralCodePageState();
}

class _UserReferralCodePageState extends ConsumerState<UserReferralCodePage> with TickerProviderStateMixin {
  late TabController _tabController, _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _controller = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifier = ref.read(profileProvider.notifier);
      //ref.watch(homeProvider(0).notifier).checkOwnerTariffs();
      // One-shot read inside initState callback — don't subscribe.
      ref.read(homeProvider(0)).ownerTariffsCheck?.data?.owner?.ownerReferalId != null ? notifier.getInvitedUsers() : null;
      notifier.getPaidUsers();
      notifier.getBalanceHistory();
      ref.read(referralRewardsProvider.notifier).load();
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);
    final homeState = ref.watch(homeProvider(0).select((s) => (
          ownerTariffsCheck: s.ownerTariffsCheck,
        )));
    final isReferralCodeExists = homeState.ownerTariffsCheck?.data?.owner?.ownedReferalCode != null;
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          "${AppLocalization.getText(context)?.referral_system}",
          fontSize: 18.sp,
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          //notifier.getInvitedUsers();
          await ref.watch(homeProvider(0).notifier).checkOwnerTariffs();
          await notifier.getBalanceHistory(isRefresh: true);
          await ref.read(referralRewardsProvider.notifier).load();
        },
        child: CustomShimmerEffect(
          isLoading: state.isLoading,
          leaf: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.all(16.sp),
                        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor,
                              AppColors.primaryColor.withAlpha(350),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  '${AppLocalization.getText(context)?.referral_balance}',
                                  fontSize: 14.sp,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                GestureDetector(
                                    onTap: () {
                                      AppHelpers.appAlertDialog(
                                          context: context,
                                          isQuestionMark: false,
                                          title: "${AppLocalization.getText(context)?.create_your_referral_code}",
                                          // The purchase reward is described only while the
                                          // backend runs it (Trello #544).
                                          content: ref.read(referralRewardsProvider).data.enabled
                                              ? "${AppLocalization.getText(context)?.referral_code_bonus}\n\n${AppLocalization.getText(context)?.referral_code_bonus_purchase}"
                                              : "${AppLocalization.getText(context)?.referral_code_bonus}",
                                      );
                                    },
                                    child: CustomSvgWidgetAsset(Assets.infoIconSvg, color: context.palette.textSecondary))
                              ],
                            ),
                            4.verticalSpace,
                            AppText(
                              '${AppMoneyFormatter.longFormatDouble(state.balanceHistory?.totalBalance ?? 0)} UZS',
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 45.sp,
                        right: 35.sp,
                        child: Transform.rotate(
                          angle: math.pi * -0.35, // Поворот на 135 градусов (3/4 пи)
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const ReferralRewardsSection(),
                  DefaultTabController(
                    length: 2,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12.sp),
                      height: 50.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Theme.of(context).canvasColor,
                      ),
                      child: Row(
                        children: List.generate(
                          2, (index) => Expanded(
                            child: GestureDetector(
                              onTap: () {
                                notifier.changeTabIndex(index: index);
                                _tabController.animateTo(index,
                                    duration: const Duration(
                                        milliseconds: 450));
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 8.sp),
                                height: 38.h,
                                width: 103.w,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: state.index == index
                                      ? Theme.of(context).tabBarTheme.labelColor
                                      : AppColors.transparent,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: state.index == index
                                        ? context.palette.accent
                                        : AppColors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: AppText(notifier.buildOuterTabs(context)[index]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),

              if(state.index == 0) ...[
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.sp),
                    child: Column(
                      children: [
                        12.verticalSpace,
                        isReferralCodeExists
                            ? AppSearchTextField<AppContact>(
                          focusNode: _phoneFocusNode,
                          isLoading: state.isLoading,
                          controller: notifier.inviteLinkController,
                          inputName: "${AppLocalization.getText(context)?.who_you_will_invite}" ,
                          findCallback: (value) async {
                            if(notifier.inviteLinkController.text.length == 12){
                              return [];
                            }
                            List<AppContact>? contact;
                            try {
                              contact = await Future.delayed(Duration.zero, () {
                                return ref
                                    .read(addContactModalWidgetProvider.notifier)
                                    .findClients(value.reFormat,
                                    localContacts: ref
                                        .read(clientContactProvider)
                                        .localContacts);
                              });
                            } catch (e) {
                              contact = [];
                            }
                            return contact ?? [];
                          },
                          itemBuilder: (context, suggestion) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ClientCardWidget(
                                clientLocalId: (suggestion.id?.isNotEmpty ?? false ? suggestion.id : "0"),
                                words: notifier.inviteLinkController.text.format,
                                name: suggestion.firstname ?? "",
                                phoneNumber: suggestion.phone?.toString().format ?? '',
                                onTap: () {
                                  final phone = suggestion.phone?.toString() ?? '';
                                  String formatted = phone;
                                  if (phone.startsWith('+998')) {
                                    formatted = phone.substring(4);
                                  }
                                  // Форматируем номер: 91 234 56 78
                                  formatted = MaskedInputFormatter('## ### ## ##').formatEditUpdate(
                                    const TextEditingValue(),
                                    TextEditingValue(text: formatted),
                                  ).text;
                                  notifier.inviteLinkController.text = formatted;
                                  _phoneFocusNode.unfocus();
                                },
                              ),
                            );
                          },
                          onChanged: (val){
                            notifier.referralTextFieldDisability(isReferralCodeExists);
                          },
                        )
                            : CustomTextField(
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [UpperCaseTextFormatter()],
                          controller: notifier.referralCodeController,
                          title: "${AppLocalization.getText(context)?.referral_code}",
                          labelText: "${AppLocalization.getText(context)?.enter_referral_code}",
                          onChanged: (value){

                          },
                        ),
                        12.verticalSpace,
                        CustomButtonWidget(
                          title: isReferralCodeExists
                              ? "${AppLocalization.getText(context)?.invite_users}"
                              : "${AppLocalization.getText(context)?.create}",
                          isLoading: state.isLoading,
                          onTap: () {
                            if(!isReferralCodeExists && notifier.referralCodeController.text.length < 6) {
                              return AppHelpers.showSnackBarError(errorMessage: "${AppLocalization.getText(context)?.min_ref_code_length}");
                            }

                            isReferralCodeExists
                                ? notifier.sendInviteLink(
                                context: context,
                                success: (){
                                  notifier.inviteLinkController.clear();
                                  notifier.getInvitedUsers();
                                }
                            )
                                : notifier.createUserReferralCode(
                                referralCode: notifier.referralCodeController.text.toUpperCase(),
                                userID: state.userInfoData?.data?.id ?? 0,
                                context: context,
                                success: () {
                                  try {
                                    MixpanelAnalyticsService.instance.track(MixpanelEvents.referralCodeCreated);
                                  } catch (_) {}
                                  ref.read(homeProvider(0).notifier).checkOwnerTariffs();
                                }
                            )  ;
                          },
                        ),
                        12.verticalSpace,
                        if (isReferralCodeExists) ...[
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: context.palette.accent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  "${AppLocalization.getText(context)?.your_referral_code}",
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                                8.verticalSpace,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppText(
                                      homeState.ownerTariffsCheck?.data?.owner?.ownedReferalCode ?? "",
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                          text: homeState.ownerTariffsCheck?.data?.owner?.ownedReferalCode ?? "",
                                        ));
                                      },
                                      icon: const Icon(Icons.copy),
                                    ),
                                  ],
                                ),
                                4.verticalSpace,
                                AppText(
                                 "${AppLocalization.getText(context)?.filling_referral_balance_title}",
                                  fontSize: 8.sp,
                                  maxLines: 2,
                                  color: context.isDark
                                      ? context.palette.accent
                                      : AppColors.primaryColorShade600,
                                ),
                              ],
                            ),
                          ),
                          8.verticalSpace,
                          ReferralStandButton(
                            ownedReferalCode: homeState.ownerTariffsCheck?.data?.owner?.ownedReferalCode,
                          ),
                          12.verticalSpace
                        ],
                        Transform.scale(
                          scale: 0.9,
                          child: DefaultTabController(
                            length: 2,
                            child: Container(
                              height: 50.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                color: Theme.of(context).canvasColor,
                              ),
                              child: Row(
                                children: List.generate(
                                  2, (index) => Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      notifier.changeSubTabIndex(index: index);
                                      _controller.animateTo(index,
                                          duration: const Duration(
                                              milliseconds: 450));
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 8.sp),
                                      height: 38.h,
                                      width: 103.w,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: state.subTabIndex == index
                                            ? Theme.of(context).tabBarTheme.labelColor
                                            : AppColors.transparent,
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(
                                          color: state.subTabIndex == index
                                              ? context.palette.accent
                                              : AppColors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: AppText(notifier.buildInnerTabs(context)[index]),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                state.subTabIndex == 0 ? const InvitedUsersThroughReferralWidget() : const PaidUsersThroughReferralWidget()
              ] else ...[
                const BalanceHistoryPage()
              ]
            ],
          ),
        ),
      ),
    );
  }
}

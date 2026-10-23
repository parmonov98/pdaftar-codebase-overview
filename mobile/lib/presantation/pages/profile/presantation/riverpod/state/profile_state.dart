import 'package:pdaftaruz/presantation/pages/applications/data/make_payment_response.dart';
import 'package:pdaftaruz/presantation/pages/applications/data/sms_tariffs_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/app_version_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/balance_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/invite_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/invited_users_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/profile_update_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/send_invite_link_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_count_price_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/my_sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/seller_owner_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_usage_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/wallet_balance_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sessions_response.dart';
import 'dart:io';

import 'package:pdaftaruz/presantation/pages/profile/data/user_info_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../global_widgets/top_up_user_balance_response.dart';
import '../../../../home/presantation/widgets/wallet_balance_response.dart';
import '../../../data/create_user_referral_response.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    @Default(false) bool isError,
    @Default(false) bool isUpdateLoading,
    @Default(false) bool isNotificationOn,
    @Default(false) bool isDeleteUserLoading,
    @Default(false) bool isBalanceHistoryLoading,
    @Default(false) bool isLoadingSessions,
    @Default(false) bool isDeletingSession,
    @Default(true) bool textFieldDisability,
    @Default(true) bool isPinCodeEnabled,  // PIN kod yoqilganmi
    @Default(false) bool isBiometricEnabled,  // Biometrik kirish yoqilganmi
    @Default(true) bool hasSellerBalance,
    @Default("") String errorMessage,
    @Default("wallet") String paymentService,
    @Default("click") String paymentService2,
    @Default(0) int index,
    @Default(0) int subTabIndex,
    @Default(0) int smsTariffID,
    @Default(0) int nextPage,
    @Default(12400) int oneDollarInSum,
    ProfileUpdateResponse? updateData,
    UserInfoResponse? userInfoData,
    // Owner of the seller's currently-attached shop. Populated only
    // when the logged-in user is a seller (Profil tab renders this in
    // place of the seller's own name/phone/avatar).
    SellerOwnerResponse? sellerOwnerData,
    AppVersionResponse? appVersionData,
    CreateUserReferralResponse? createUserReferralData,
    InvitedUsersResponse? invitedUsersData,
    InvitedUsersResponse? paidUsersData,
    MakePaymentResponse? paymentSMSUrl,
    SmsTariffsResponse? smsTariffs,
    ReferralBonusResponse? balanceHistory,
    SmsHistoryResponse? smsHistory,
    MySmsHistoryResponse? mySmsHistory,
    SmsUsageSummaryResponse? smsUsageSummary,
    InviteHistoryResponse? invitedHistory,
    SendInviteLinkResponse? sendInviteLink,
    GetSmsCountPriceResponse? smsCountPrice,
    TopUpUserBalanceResponse? topUpUserBalanceLink,
    // Null = not yet attempted; true = auto-launch succeeded; false =
    // every fallback failed. Drives the status banner above the
    // "Open in browser" button in the top-up bottom sheet so users
    // can see whether anything happened automatically.
    bool? lastPaymentLaunchSucceeded,
    WalletBalanceResponse? walletBalance,
    WalletBalanceSummaryResponse? walletBalanceSummary,
    @Default(false) bool isWalletBalanceSummaryLoading,
    SessionsResponse? sessionsData,
    // ignore: invalid_annotation_target — freezed forwards this to the field.
    @JsonKey(includeFromJson: false, includeToJson: false) File? selectedImageFile,
  }) = _ProfileState;
}
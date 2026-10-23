// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProfileState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isError => throw _privateConstructorUsedError;
  bool get isUpdateLoading => throw _privateConstructorUsedError;
  bool get isNotificationOn => throw _privateConstructorUsedError;
  bool get isDeleteUserLoading => throw _privateConstructorUsedError;
  bool get isBalanceHistoryLoading => throw _privateConstructorUsedError;
  bool get isLoadingSessions => throw _privateConstructorUsedError;
  bool get isDeletingSession => throw _privateConstructorUsedError;
  bool get textFieldDisability => throw _privateConstructorUsedError;
  bool get isPinCodeEnabled =>
      throw _privateConstructorUsedError; // PIN kod yoqilganmi
  bool get isBiometricEnabled =>
      throw _privateConstructorUsedError; // Biometrik kirish yoqilganmi
  bool get hasSellerBalance => throw _privateConstructorUsedError;
  String get errorMessage => throw _privateConstructorUsedError;
  String get paymentService => throw _privateConstructorUsedError;
  String get paymentService2 => throw _privateConstructorUsedError;
  int get index => throw _privateConstructorUsedError;
  int get subTabIndex => throw _privateConstructorUsedError;
  int get smsTariffID => throw _privateConstructorUsedError;
  int get nextPage => throw _privateConstructorUsedError;
  int get oneDollarInSum => throw _privateConstructorUsedError;
  ProfileUpdateResponse? get updateData => throw _privateConstructorUsedError;
  UserInfoResponse? get userInfoData =>
      throw _privateConstructorUsedError; // Owner of the seller's currently-attached shop. Populated only
// when the logged-in user is a seller (Profil tab renders this in
// place of the seller's own name/phone/avatar).
  SellerOwnerResponse? get sellerOwnerData =>
      throw _privateConstructorUsedError;
  AppVersionResponse? get appVersionData => throw _privateConstructorUsedError;
  CreateUserReferralResponse? get createUserReferralData =>
      throw _privateConstructorUsedError;
  InvitedUsersResponse? get invitedUsersData =>
      throw _privateConstructorUsedError;
  InvitedUsersResponse? get paidUsersData => throw _privateConstructorUsedError;
  MakePaymentResponse? get paymentSMSUrl => throw _privateConstructorUsedError;
  SmsTariffsResponse? get smsTariffs => throw _privateConstructorUsedError;
  ReferralBonusResponse? get balanceHistory =>
      throw _privateConstructorUsedError;
  SmsHistoryResponse? get smsHistory => throw _privateConstructorUsedError;
  MySmsHistoryResponse? get mySmsHistory => throw _privateConstructorUsedError;
  SmsUsageSummaryResponse? get smsUsageSummary =>
      throw _privateConstructorUsedError;
  InviteHistoryResponse? get invitedHistory =>
      throw _privateConstructorUsedError;
  SendInviteLinkResponse? get sendInviteLink =>
      throw _privateConstructorUsedError;
  GetSmsCountPriceResponse? get smsCountPrice =>
      throw _privateConstructorUsedError;
  TopUpUserBalanceResponse? get topUpUserBalanceLink =>
      throw _privateConstructorUsedError; // Null = not yet attempted; true = auto-launch succeeded; false =
// every fallback failed. Drives the status banner above the
// "Open in browser" button in the top-up bottom sheet so users
// can see whether anything happened automatically.
  bool? get lastPaymentLaunchSucceeded => throw _privateConstructorUsedError;
  WalletBalanceResponse? get walletBalance =>
      throw _privateConstructorUsedError;
  WalletBalanceSummaryResponse? get walletBalanceSummary =>
      throw _privateConstructorUsedError;
  bool get isWalletBalanceSummaryLoading => throw _privateConstructorUsedError;
  SessionsResponse? get sessionsData => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  File? get selectedImageFile => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ProfileStateCopyWith<ProfileState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileStateCopyWith<$Res> {
  factory $ProfileStateCopyWith(
          ProfileState value, $Res Function(ProfileState) then) =
      _$ProfileStateCopyWithImpl<$Res, ProfileState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isError,
      bool isUpdateLoading,
      bool isNotificationOn,
      bool isDeleteUserLoading,
      bool isBalanceHistoryLoading,
      bool isLoadingSessions,
      bool isDeletingSession,
      bool textFieldDisability,
      bool isPinCodeEnabled,
      bool isBiometricEnabled,
      bool hasSellerBalance,
      String errorMessage,
      String paymentService,
      String paymentService2,
      int index,
      int subTabIndex,
      int smsTariffID,
      int nextPage,
      int oneDollarInSum,
      ProfileUpdateResponse? updateData,
      UserInfoResponse? userInfoData,
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
      bool? lastPaymentLaunchSucceeded,
      WalletBalanceResponse? walletBalance,
      WalletBalanceSummaryResponse? walletBalanceSummary,
      bool isWalletBalanceSummaryLoading,
      SessionsResponse? sessionsData,
      @JsonKey(includeFromJson: false, includeToJson: false)
      File? selectedImageFile});
}

/// @nodoc
class _$ProfileStateCopyWithImpl<$Res, $Val extends ProfileState>
    implements $ProfileStateCopyWith<$Res> {
  _$ProfileStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isError = null,
    Object? isUpdateLoading = null,
    Object? isNotificationOn = null,
    Object? isDeleteUserLoading = null,
    Object? isBalanceHistoryLoading = null,
    Object? isLoadingSessions = null,
    Object? isDeletingSession = null,
    Object? textFieldDisability = null,
    Object? isPinCodeEnabled = null,
    Object? isBiometricEnabled = null,
    Object? hasSellerBalance = null,
    Object? errorMessage = null,
    Object? paymentService = null,
    Object? paymentService2 = null,
    Object? index = null,
    Object? subTabIndex = null,
    Object? smsTariffID = null,
    Object? nextPage = null,
    Object? oneDollarInSum = null,
    Object? updateData = freezed,
    Object? userInfoData = freezed,
    Object? sellerOwnerData = freezed,
    Object? appVersionData = freezed,
    Object? createUserReferralData = freezed,
    Object? invitedUsersData = freezed,
    Object? paidUsersData = freezed,
    Object? paymentSMSUrl = freezed,
    Object? smsTariffs = freezed,
    Object? balanceHistory = freezed,
    Object? smsHistory = freezed,
    Object? mySmsHistory = freezed,
    Object? smsUsageSummary = freezed,
    Object? invitedHistory = freezed,
    Object? sendInviteLink = freezed,
    Object? smsCountPrice = freezed,
    Object? topUpUserBalanceLink = freezed,
    Object? lastPaymentLaunchSucceeded = freezed,
    Object? walletBalance = freezed,
    Object? walletBalanceSummary = freezed,
    Object? isWalletBalanceSummaryLoading = null,
    Object? sessionsData = freezed,
    Object? selectedImageFile = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdateLoading: null == isUpdateLoading
          ? _value.isUpdateLoading
          : isUpdateLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isNotificationOn: null == isNotificationOn
          ? _value.isNotificationOn
          : isNotificationOn // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleteUserLoading: null == isDeleteUserLoading
          ? _value.isDeleteUserLoading
          : isDeleteUserLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBalanceHistoryLoading: null == isBalanceHistoryLoading
          ? _value.isBalanceHistoryLoading
          : isBalanceHistoryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingSessions: null == isLoadingSessions
          ? _value.isLoadingSessions
          : isLoadingSessions // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeletingSession: null == isDeletingSession
          ? _value.isDeletingSession
          : isDeletingSession // ignore: cast_nullable_to_non_nullable
              as bool,
      textFieldDisability: null == textFieldDisability
          ? _value.textFieldDisability
          : textFieldDisability // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinCodeEnabled: null == isPinCodeEnabled
          ? _value.isPinCodeEnabled
          : isPinCodeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isBiometricEnabled: null == isBiometricEnabled
          ? _value.isBiometricEnabled
          : isBiometricEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      hasSellerBalance: null == hasSellerBalance
          ? _value.hasSellerBalance
          : hasSellerBalance // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      paymentService: null == paymentService
          ? _value.paymentService
          : paymentService // ignore: cast_nullable_to_non_nullable
              as String,
      paymentService2: null == paymentService2
          ? _value.paymentService2
          : paymentService2 // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      subTabIndex: null == subTabIndex
          ? _value.subTabIndex
          : subTabIndex // ignore: cast_nullable_to_non_nullable
              as int,
      smsTariffID: null == smsTariffID
          ? _value.smsTariffID
          : smsTariffID // ignore: cast_nullable_to_non_nullable
              as int,
      nextPage: null == nextPage
          ? _value.nextPage
          : nextPage // ignore: cast_nullable_to_non_nullable
              as int,
      oneDollarInSum: null == oneDollarInSum
          ? _value.oneDollarInSum
          : oneDollarInSum // ignore: cast_nullable_to_non_nullable
              as int,
      updateData: freezed == updateData
          ? _value.updateData
          : updateData // ignore: cast_nullable_to_non_nullable
              as ProfileUpdateResponse?,
      userInfoData: freezed == userInfoData
          ? _value.userInfoData
          : userInfoData // ignore: cast_nullable_to_non_nullable
              as UserInfoResponse?,
      sellerOwnerData: freezed == sellerOwnerData
          ? _value.sellerOwnerData
          : sellerOwnerData // ignore: cast_nullable_to_non_nullable
              as SellerOwnerResponse?,
      appVersionData: freezed == appVersionData
          ? _value.appVersionData
          : appVersionData // ignore: cast_nullable_to_non_nullable
              as AppVersionResponse?,
      createUserReferralData: freezed == createUserReferralData
          ? _value.createUserReferralData
          : createUserReferralData // ignore: cast_nullable_to_non_nullable
              as CreateUserReferralResponse?,
      invitedUsersData: freezed == invitedUsersData
          ? _value.invitedUsersData
          : invitedUsersData // ignore: cast_nullable_to_non_nullable
              as InvitedUsersResponse?,
      paidUsersData: freezed == paidUsersData
          ? _value.paidUsersData
          : paidUsersData // ignore: cast_nullable_to_non_nullable
              as InvitedUsersResponse?,
      paymentSMSUrl: freezed == paymentSMSUrl
          ? _value.paymentSMSUrl
          : paymentSMSUrl // ignore: cast_nullable_to_non_nullable
              as MakePaymentResponse?,
      smsTariffs: freezed == smsTariffs
          ? _value.smsTariffs
          : smsTariffs // ignore: cast_nullable_to_non_nullable
              as SmsTariffsResponse?,
      balanceHistory: freezed == balanceHistory
          ? _value.balanceHistory
          : balanceHistory // ignore: cast_nullable_to_non_nullable
              as ReferralBonusResponse?,
      smsHistory: freezed == smsHistory
          ? _value.smsHistory
          : smsHistory // ignore: cast_nullable_to_non_nullable
              as SmsHistoryResponse?,
      mySmsHistory: freezed == mySmsHistory
          ? _value.mySmsHistory
          : mySmsHistory // ignore: cast_nullable_to_non_nullable
              as MySmsHistoryResponse?,
      smsUsageSummary: freezed == smsUsageSummary
          ? _value.smsUsageSummary
          : smsUsageSummary // ignore: cast_nullable_to_non_nullable
              as SmsUsageSummaryResponse?,
      invitedHistory: freezed == invitedHistory
          ? _value.invitedHistory
          : invitedHistory // ignore: cast_nullable_to_non_nullable
              as InviteHistoryResponse?,
      sendInviteLink: freezed == sendInviteLink
          ? _value.sendInviteLink
          : sendInviteLink // ignore: cast_nullable_to_non_nullable
              as SendInviteLinkResponse?,
      smsCountPrice: freezed == smsCountPrice
          ? _value.smsCountPrice
          : smsCountPrice // ignore: cast_nullable_to_non_nullable
              as GetSmsCountPriceResponse?,
      topUpUserBalanceLink: freezed == topUpUserBalanceLink
          ? _value.topUpUserBalanceLink
          : topUpUserBalanceLink // ignore: cast_nullable_to_non_nullable
              as TopUpUserBalanceResponse?,
      lastPaymentLaunchSucceeded: freezed == lastPaymentLaunchSucceeded
          ? _value.lastPaymentLaunchSucceeded
          : lastPaymentLaunchSucceeded // ignore: cast_nullable_to_non_nullable
              as bool?,
      walletBalance: freezed == walletBalance
          ? _value.walletBalance
          : walletBalance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceResponse?,
      walletBalanceSummary: freezed == walletBalanceSummary
          ? _value.walletBalanceSummary
          : walletBalanceSummary // ignore: cast_nullable_to_non_nullable
              as WalletBalanceSummaryResponse?,
      isWalletBalanceSummaryLoading: null == isWalletBalanceSummaryLoading
          ? _value.isWalletBalanceSummaryLoading
          : isWalletBalanceSummaryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionsData: freezed == sessionsData
          ? _value.sessionsData
          : sessionsData // ignore: cast_nullable_to_non_nullable
              as SessionsResponse?,
      selectedImageFile: freezed == selectedImageFile
          ? _value.selectedImageFile
          : selectedImageFile // ignore: cast_nullable_to_non_nullable
              as File?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileStateImplCopyWith<$Res>
    implements $ProfileStateCopyWith<$Res> {
  factory _$$ProfileStateImplCopyWith(
          _$ProfileStateImpl value, $Res Function(_$ProfileStateImpl) then) =
      __$$ProfileStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isError,
      bool isUpdateLoading,
      bool isNotificationOn,
      bool isDeleteUserLoading,
      bool isBalanceHistoryLoading,
      bool isLoadingSessions,
      bool isDeletingSession,
      bool textFieldDisability,
      bool isPinCodeEnabled,
      bool isBiometricEnabled,
      bool hasSellerBalance,
      String errorMessage,
      String paymentService,
      String paymentService2,
      int index,
      int subTabIndex,
      int smsTariffID,
      int nextPage,
      int oneDollarInSum,
      ProfileUpdateResponse? updateData,
      UserInfoResponse? userInfoData,
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
      bool? lastPaymentLaunchSucceeded,
      WalletBalanceResponse? walletBalance,
      WalletBalanceSummaryResponse? walletBalanceSummary,
      bool isWalletBalanceSummaryLoading,
      SessionsResponse? sessionsData,
      @JsonKey(includeFromJson: false, includeToJson: false)
      File? selectedImageFile});
}

/// @nodoc
class __$$ProfileStateImplCopyWithImpl<$Res>
    extends _$ProfileStateCopyWithImpl<$Res, _$ProfileStateImpl>
    implements _$$ProfileStateImplCopyWith<$Res> {
  __$$ProfileStateImplCopyWithImpl(
      _$ProfileStateImpl _value, $Res Function(_$ProfileStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isError = null,
    Object? isUpdateLoading = null,
    Object? isNotificationOn = null,
    Object? isDeleteUserLoading = null,
    Object? isBalanceHistoryLoading = null,
    Object? isLoadingSessions = null,
    Object? isDeletingSession = null,
    Object? textFieldDisability = null,
    Object? isPinCodeEnabled = null,
    Object? isBiometricEnabled = null,
    Object? hasSellerBalance = null,
    Object? errorMessage = null,
    Object? paymentService = null,
    Object? paymentService2 = null,
    Object? index = null,
    Object? subTabIndex = null,
    Object? smsTariffID = null,
    Object? nextPage = null,
    Object? oneDollarInSum = null,
    Object? updateData = freezed,
    Object? userInfoData = freezed,
    Object? sellerOwnerData = freezed,
    Object? appVersionData = freezed,
    Object? createUserReferralData = freezed,
    Object? invitedUsersData = freezed,
    Object? paidUsersData = freezed,
    Object? paymentSMSUrl = freezed,
    Object? smsTariffs = freezed,
    Object? balanceHistory = freezed,
    Object? smsHistory = freezed,
    Object? mySmsHistory = freezed,
    Object? smsUsageSummary = freezed,
    Object? invitedHistory = freezed,
    Object? sendInviteLink = freezed,
    Object? smsCountPrice = freezed,
    Object? topUpUserBalanceLink = freezed,
    Object? lastPaymentLaunchSucceeded = freezed,
    Object? walletBalance = freezed,
    Object? walletBalanceSummary = freezed,
    Object? isWalletBalanceSummaryLoading = null,
    Object? sessionsData = freezed,
    Object? selectedImageFile = freezed,
  }) {
    return _then(_$ProfileStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isError: null == isError
          ? _value.isError
          : isError // ignore: cast_nullable_to_non_nullable
              as bool,
      isUpdateLoading: null == isUpdateLoading
          ? _value.isUpdateLoading
          : isUpdateLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isNotificationOn: null == isNotificationOn
          ? _value.isNotificationOn
          : isNotificationOn // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeleteUserLoading: null == isDeleteUserLoading
          ? _value.isDeleteUserLoading
          : isDeleteUserLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isBalanceHistoryLoading: null == isBalanceHistoryLoading
          ? _value.isBalanceHistoryLoading
          : isBalanceHistoryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingSessions: null == isLoadingSessions
          ? _value.isLoadingSessions
          : isLoadingSessions // ignore: cast_nullable_to_non_nullable
              as bool,
      isDeletingSession: null == isDeletingSession
          ? _value.isDeletingSession
          : isDeletingSession // ignore: cast_nullable_to_non_nullable
              as bool,
      textFieldDisability: null == textFieldDisability
          ? _value.textFieldDisability
          : textFieldDisability // ignore: cast_nullable_to_non_nullable
              as bool,
      isPinCodeEnabled: null == isPinCodeEnabled
          ? _value.isPinCodeEnabled
          : isPinCodeEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isBiometricEnabled: null == isBiometricEnabled
          ? _value.isBiometricEnabled
          : isBiometricEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      hasSellerBalance: null == hasSellerBalance
          ? _value.hasSellerBalance
          : hasSellerBalance // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: null == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String,
      paymentService: null == paymentService
          ? _value.paymentService
          : paymentService // ignore: cast_nullable_to_non_nullable
              as String,
      paymentService2: null == paymentService2
          ? _value.paymentService2
          : paymentService2 // ignore: cast_nullable_to_non_nullable
              as String,
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      subTabIndex: null == subTabIndex
          ? _value.subTabIndex
          : subTabIndex // ignore: cast_nullable_to_non_nullable
              as int,
      smsTariffID: null == smsTariffID
          ? _value.smsTariffID
          : smsTariffID // ignore: cast_nullable_to_non_nullable
              as int,
      nextPage: null == nextPage
          ? _value.nextPage
          : nextPage // ignore: cast_nullable_to_non_nullable
              as int,
      oneDollarInSum: null == oneDollarInSum
          ? _value.oneDollarInSum
          : oneDollarInSum // ignore: cast_nullable_to_non_nullable
              as int,
      updateData: freezed == updateData
          ? _value.updateData
          : updateData // ignore: cast_nullable_to_non_nullable
              as ProfileUpdateResponse?,
      userInfoData: freezed == userInfoData
          ? _value.userInfoData
          : userInfoData // ignore: cast_nullable_to_non_nullable
              as UserInfoResponse?,
      sellerOwnerData: freezed == sellerOwnerData
          ? _value.sellerOwnerData
          : sellerOwnerData // ignore: cast_nullable_to_non_nullable
              as SellerOwnerResponse?,
      appVersionData: freezed == appVersionData
          ? _value.appVersionData
          : appVersionData // ignore: cast_nullable_to_non_nullable
              as AppVersionResponse?,
      createUserReferralData: freezed == createUserReferralData
          ? _value.createUserReferralData
          : createUserReferralData // ignore: cast_nullable_to_non_nullable
              as CreateUserReferralResponse?,
      invitedUsersData: freezed == invitedUsersData
          ? _value.invitedUsersData
          : invitedUsersData // ignore: cast_nullable_to_non_nullable
              as InvitedUsersResponse?,
      paidUsersData: freezed == paidUsersData
          ? _value.paidUsersData
          : paidUsersData // ignore: cast_nullable_to_non_nullable
              as InvitedUsersResponse?,
      paymentSMSUrl: freezed == paymentSMSUrl
          ? _value.paymentSMSUrl
          : paymentSMSUrl // ignore: cast_nullable_to_non_nullable
              as MakePaymentResponse?,
      smsTariffs: freezed == smsTariffs
          ? _value.smsTariffs
          : smsTariffs // ignore: cast_nullable_to_non_nullable
              as SmsTariffsResponse?,
      balanceHistory: freezed == balanceHistory
          ? _value.balanceHistory
          : balanceHistory // ignore: cast_nullable_to_non_nullable
              as ReferralBonusResponse?,
      smsHistory: freezed == smsHistory
          ? _value.smsHistory
          : smsHistory // ignore: cast_nullable_to_non_nullable
              as SmsHistoryResponse?,
      mySmsHistory: freezed == mySmsHistory
          ? _value.mySmsHistory
          : mySmsHistory // ignore: cast_nullable_to_non_nullable
              as MySmsHistoryResponse?,
      smsUsageSummary: freezed == smsUsageSummary
          ? _value.smsUsageSummary
          : smsUsageSummary // ignore: cast_nullable_to_non_nullable
              as SmsUsageSummaryResponse?,
      invitedHistory: freezed == invitedHistory
          ? _value.invitedHistory
          : invitedHistory // ignore: cast_nullable_to_non_nullable
              as InviteHistoryResponse?,
      sendInviteLink: freezed == sendInviteLink
          ? _value.sendInviteLink
          : sendInviteLink // ignore: cast_nullable_to_non_nullable
              as SendInviteLinkResponse?,
      smsCountPrice: freezed == smsCountPrice
          ? _value.smsCountPrice
          : smsCountPrice // ignore: cast_nullable_to_non_nullable
              as GetSmsCountPriceResponse?,
      topUpUserBalanceLink: freezed == topUpUserBalanceLink
          ? _value.topUpUserBalanceLink
          : topUpUserBalanceLink // ignore: cast_nullable_to_non_nullable
              as TopUpUserBalanceResponse?,
      lastPaymentLaunchSucceeded: freezed == lastPaymentLaunchSucceeded
          ? _value.lastPaymentLaunchSucceeded
          : lastPaymentLaunchSucceeded // ignore: cast_nullable_to_non_nullable
              as bool?,
      walletBalance: freezed == walletBalance
          ? _value.walletBalance
          : walletBalance // ignore: cast_nullable_to_non_nullable
              as WalletBalanceResponse?,
      walletBalanceSummary: freezed == walletBalanceSummary
          ? _value.walletBalanceSummary
          : walletBalanceSummary // ignore: cast_nullable_to_non_nullable
              as WalletBalanceSummaryResponse?,
      isWalletBalanceSummaryLoading: null == isWalletBalanceSummaryLoading
          ? _value.isWalletBalanceSummaryLoading
          : isWalletBalanceSummaryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      sessionsData: freezed == sessionsData
          ? _value.sessionsData
          : sessionsData // ignore: cast_nullable_to_non_nullable
              as SessionsResponse?,
      selectedImageFile: freezed == selectedImageFile
          ? _value.selectedImageFile
          : selectedImageFile // ignore: cast_nullable_to_non_nullable
              as File?,
    ));
  }
}

/// @nodoc

class _$ProfileStateImpl implements _ProfileState {
  const _$ProfileStateImpl(
      {this.isLoading = false,
      this.isError = false,
      this.isUpdateLoading = false,
      this.isNotificationOn = false,
      this.isDeleteUserLoading = false,
      this.isBalanceHistoryLoading = false,
      this.isLoadingSessions = false,
      this.isDeletingSession = false,
      this.textFieldDisability = true,
      this.isPinCodeEnabled = true,
      this.isBiometricEnabled = false,
      this.hasSellerBalance = true,
      this.errorMessage = "",
      this.paymentService = "wallet",
      this.paymentService2 = "click",
      this.index = 0,
      this.subTabIndex = 0,
      this.smsTariffID = 0,
      this.nextPage = 0,
      this.oneDollarInSum = 12400,
      this.updateData,
      this.userInfoData,
      this.sellerOwnerData,
      this.appVersionData,
      this.createUserReferralData,
      this.invitedUsersData,
      this.paidUsersData,
      this.paymentSMSUrl,
      this.smsTariffs,
      this.balanceHistory,
      this.smsHistory,
      this.mySmsHistory,
      this.smsUsageSummary,
      this.invitedHistory,
      this.sendInviteLink,
      this.smsCountPrice,
      this.topUpUserBalanceLink,
      this.lastPaymentLaunchSucceeded,
      this.walletBalance,
      this.walletBalanceSummary,
      this.isWalletBalanceSummaryLoading = false,
      this.sessionsData,
      @JsonKey(includeFromJson: false, includeToJson: false)
      this.selectedImageFile});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isError;
  @override
  @JsonKey()
  final bool isUpdateLoading;
  @override
  @JsonKey()
  final bool isNotificationOn;
  @override
  @JsonKey()
  final bool isDeleteUserLoading;
  @override
  @JsonKey()
  final bool isBalanceHistoryLoading;
  @override
  @JsonKey()
  final bool isLoadingSessions;
  @override
  @JsonKey()
  final bool isDeletingSession;
  @override
  @JsonKey()
  final bool textFieldDisability;
  @override
  @JsonKey()
  final bool isPinCodeEnabled;
// PIN kod yoqilganmi
  @override
  @JsonKey()
  final bool isBiometricEnabled;
// Biometrik kirish yoqilganmi
  @override
  @JsonKey()
  final bool hasSellerBalance;
  @override
  @JsonKey()
  final String errorMessage;
  @override
  @JsonKey()
  final String paymentService;
  @override
  @JsonKey()
  final String paymentService2;
  @override
  @JsonKey()
  final int index;
  @override
  @JsonKey()
  final int subTabIndex;
  @override
  @JsonKey()
  final int smsTariffID;
  @override
  @JsonKey()
  final int nextPage;
  @override
  @JsonKey()
  final int oneDollarInSum;
  @override
  final ProfileUpdateResponse? updateData;
  @override
  final UserInfoResponse? userInfoData;
// Owner of the seller's currently-attached shop. Populated only
// when the logged-in user is a seller (Profil tab renders this in
// place of the seller's own name/phone/avatar).
  @override
  final SellerOwnerResponse? sellerOwnerData;
  @override
  final AppVersionResponse? appVersionData;
  @override
  final CreateUserReferralResponse? createUserReferralData;
  @override
  final InvitedUsersResponse? invitedUsersData;
  @override
  final InvitedUsersResponse? paidUsersData;
  @override
  final MakePaymentResponse? paymentSMSUrl;
  @override
  final SmsTariffsResponse? smsTariffs;
  @override
  final ReferralBonusResponse? balanceHistory;
  @override
  final SmsHistoryResponse? smsHistory;
  @override
  final MySmsHistoryResponse? mySmsHistory;
  @override
  final SmsUsageSummaryResponse? smsUsageSummary;
  @override
  final InviteHistoryResponse? invitedHistory;
  @override
  final SendInviteLinkResponse? sendInviteLink;
  @override
  final GetSmsCountPriceResponse? smsCountPrice;
  @override
  final TopUpUserBalanceResponse? topUpUserBalanceLink;
// Null = not yet attempted; true = auto-launch succeeded; false =
// every fallback failed. Drives the status banner above the
// "Open in browser" button in the top-up bottom sheet so users
// can see whether anything happened automatically.
  @override
  final bool? lastPaymentLaunchSucceeded;
  @override
  final WalletBalanceResponse? walletBalance;
  @override
  final WalletBalanceSummaryResponse? walletBalanceSummary;
  @override
  @JsonKey()
  final bool isWalletBalanceSummaryLoading;
  @override
  final SessionsResponse? sessionsData;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final File? selectedImageFile;

  @override
  String toString() {
    return 'ProfileState(isLoading: $isLoading, isError: $isError, isUpdateLoading: $isUpdateLoading, isNotificationOn: $isNotificationOn, isDeleteUserLoading: $isDeleteUserLoading, isBalanceHistoryLoading: $isBalanceHistoryLoading, isLoadingSessions: $isLoadingSessions, isDeletingSession: $isDeletingSession, textFieldDisability: $textFieldDisability, isPinCodeEnabled: $isPinCodeEnabled, isBiometricEnabled: $isBiometricEnabled, hasSellerBalance: $hasSellerBalance, errorMessage: $errorMessage, paymentService: $paymentService, paymentService2: $paymentService2, index: $index, subTabIndex: $subTabIndex, smsTariffID: $smsTariffID, nextPage: $nextPage, oneDollarInSum: $oneDollarInSum, updateData: $updateData, userInfoData: $userInfoData, sellerOwnerData: $sellerOwnerData, appVersionData: $appVersionData, createUserReferralData: $createUserReferralData, invitedUsersData: $invitedUsersData, paidUsersData: $paidUsersData, paymentSMSUrl: $paymentSMSUrl, smsTariffs: $smsTariffs, balanceHistory: $balanceHistory, smsHistory: $smsHistory, mySmsHistory: $mySmsHistory, smsUsageSummary: $smsUsageSummary, invitedHistory: $invitedHistory, sendInviteLink: $sendInviteLink, smsCountPrice: $smsCountPrice, topUpUserBalanceLink: $topUpUserBalanceLink, lastPaymentLaunchSucceeded: $lastPaymentLaunchSucceeded, walletBalance: $walletBalance, walletBalanceSummary: $walletBalanceSummary, isWalletBalanceSummaryLoading: $isWalletBalanceSummaryLoading, sessionsData: $sessionsData, selectedImageFile: $selectedImageFile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isError, isError) || other.isError == isError) &&
            (identical(other.isUpdateLoading, isUpdateLoading) ||
                other.isUpdateLoading == isUpdateLoading) &&
            (identical(other.isNotificationOn, isNotificationOn) ||
                other.isNotificationOn == isNotificationOn) &&
            (identical(other.isDeleteUserLoading, isDeleteUserLoading) ||
                other.isDeleteUserLoading == isDeleteUserLoading) &&
            (identical(other.isBalanceHistoryLoading, isBalanceHistoryLoading) ||
                other.isBalanceHistoryLoading == isBalanceHistoryLoading) &&
            (identical(other.isLoadingSessions, isLoadingSessions) ||
                other.isLoadingSessions == isLoadingSessions) &&
            (identical(other.isDeletingSession, isDeletingSession) ||
                other.isDeletingSession == isDeletingSession) &&
            (identical(other.textFieldDisability, textFieldDisability) ||
                other.textFieldDisability == textFieldDisability) &&
            (identical(other.isPinCodeEnabled, isPinCodeEnabled) ||
                other.isPinCodeEnabled == isPinCodeEnabled) &&
            (identical(other.isBiometricEnabled, isBiometricEnabled) ||
                other.isBiometricEnabled == isBiometricEnabled) &&
            (identical(other.hasSellerBalance, hasSellerBalance) ||
                other.hasSellerBalance == hasSellerBalance) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.paymentService, paymentService) ||
                other.paymentService == paymentService) &&
            (identical(other.paymentService2, paymentService2) ||
                other.paymentService2 == paymentService2) &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.subTabIndex, subTabIndex) ||
                other.subTabIndex == subTabIndex) &&
            (identical(other.smsTariffID, smsTariffID) ||
                other.smsTariffID == smsTariffID) &&
            (identical(other.nextPage, nextPage) ||
                other.nextPage == nextPage) &&
            (identical(other.oneDollarInSum, oneDollarInSum) ||
                other.oneDollarInSum == oneDollarInSum) &&
            (identical(other.updateData, updateData) ||
                other.updateData == updateData) &&
            (identical(other.userInfoData, userInfoData) ||
                other.userInfoData == userInfoData) &&
            (identical(other.sellerOwnerData, sellerOwnerData) ||
                other.sellerOwnerData == sellerOwnerData) &&
            (identical(other.appVersionData, appVersionData) ||
                other.appVersionData == appVersionData) &&
            (identical(other.createUserReferralData, createUserReferralData) ||
                other.createUserReferralData == createUserReferralData) &&
            (identical(other.invitedUsersData, invitedUsersData) ||
                other.invitedUsersData == invitedUsersData) &&
            (identical(other.paidUsersData, paidUsersData) ||
                other.paidUsersData == paidUsersData) &&
            (identical(other.paymentSMSUrl, paymentSMSUrl) ||
                other.paymentSMSUrl == paymentSMSUrl) &&
            (identical(other.smsTariffs, smsTariffs) ||
                other.smsTariffs == smsTariffs) &&
            (identical(other.balanceHistory, balanceHistory) ||
                other.balanceHistory == balanceHistory) &&
            (identical(other.smsHistory, smsHistory) ||
                other.smsHistory == smsHistory) &&
            (identical(other.mySmsHistory, mySmsHistory) ||
                other.mySmsHistory == mySmsHistory) &&
            (identical(other.smsUsageSummary, smsUsageSummary) ||
                other.smsUsageSummary == smsUsageSummary) &&
            (identical(other.invitedHistory, invitedHistory) ||
                other.invitedHistory == invitedHistory) &&
            (identical(other.sendInviteLink, sendInviteLink) ||
                other.sendInviteLink == sendInviteLink) &&
            (identical(other.smsCountPrice, smsCountPrice) || other.smsCountPrice == smsCountPrice) &&
            (identical(other.topUpUserBalanceLink, topUpUserBalanceLink) || other.topUpUserBalanceLink == topUpUserBalanceLink) &&
            (identical(other.lastPaymentLaunchSucceeded, lastPaymentLaunchSucceeded) || other.lastPaymentLaunchSucceeded == lastPaymentLaunchSucceeded) &&
            (identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance) &&
            (identical(other.walletBalanceSummary, walletBalanceSummary) || other.walletBalanceSummary == walletBalanceSummary) &&
            (identical(other.isWalletBalanceSummaryLoading, isWalletBalanceSummaryLoading) || other.isWalletBalanceSummaryLoading == isWalletBalanceSummaryLoading) &&
            (identical(other.sessionsData, sessionsData) || other.sessionsData == sessionsData) &&
            (identical(other.selectedImageFile, selectedImageFile) || other.selectedImageFile == selectedImageFile));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        isLoading,
        isError,
        isUpdateLoading,
        isNotificationOn,
        isDeleteUserLoading,
        isBalanceHistoryLoading,
        isLoadingSessions,
        isDeletingSession,
        textFieldDisability,
        isPinCodeEnabled,
        isBiometricEnabled,
        hasSellerBalance,
        errorMessage,
        paymentService,
        paymentService2,
        index,
        subTabIndex,
        smsTariffID,
        nextPage,
        oneDollarInSum,
        updateData,
        userInfoData,
        sellerOwnerData,
        appVersionData,
        createUserReferralData,
        invitedUsersData,
        paidUsersData,
        paymentSMSUrl,
        smsTariffs,
        balanceHistory,
        smsHistory,
        mySmsHistory,
        smsUsageSummary,
        invitedHistory,
        sendInviteLink,
        smsCountPrice,
        topUpUserBalanceLink,
        lastPaymentLaunchSucceeded,
        walletBalance,
        walletBalanceSummary,
        isWalletBalanceSummaryLoading,
        sessionsData,
        selectedImageFile
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      __$$ProfileStateImplCopyWithImpl<_$ProfileStateImpl>(this, _$identity);
}

abstract class _ProfileState implements ProfileState {
  const factory _ProfileState(
      {final bool isLoading,
      final bool isError,
      final bool isUpdateLoading,
      final bool isNotificationOn,
      final bool isDeleteUserLoading,
      final bool isBalanceHistoryLoading,
      final bool isLoadingSessions,
      final bool isDeletingSession,
      final bool textFieldDisability,
      final bool isPinCodeEnabled,
      final bool isBiometricEnabled,
      final bool hasSellerBalance,
      final String errorMessage,
      final String paymentService,
      final String paymentService2,
      final int index,
      final int subTabIndex,
      final int smsTariffID,
      final int nextPage,
      final int oneDollarInSum,
      final ProfileUpdateResponse? updateData,
      final UserInfoResponse? userInfoData,
      final SellerOwnerResponse? sellerOwnerData,
      final AppVersionResponse? appVersionData,
      final CreateUserReferralResponse? createUserReferralData,
      final InvitedUsersResponse? invitedUsersData,
      final InvitedUsersResponse? paidUsersData,
      final MakePaymentResponse? paymentSMSUrl,
      final SmsTariffsResponse? smsTariffs,
      final ReferralBonusResponse? balanceHistory,
      final SmsHistoryResponse? smsHistory,
      final MySmsHistoryResponse? mySmsHistory,
      final SmsUsageSummaryResponse? smsUsageSummary,
      final InviteHistoryResponse? invitedHistory,
      final SendInviteLinkResponse? sendInviteLink,
      final GetSmsCountPriceResponse? smsCountPrice,
      final TopUpUserBalanceResponse? topUpUserBalanceLink,
      final bool? lastPaymentLaunchSucceeded,
      final WalletBalanceResponse? walletBalance,
      final WalletBalanceSummaryResponse? walletBalanceSummary,
      final bool isWalletBalanceSummaryLoading,
      final SessionsResponse? sessionsData,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final File? selectedImageFile}) = _$ProfileStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isError;
  @override
  bool get isUpdateLoading;
  @override
  bool get isNotificationOn;
  @override
  bool get isDeleteUserLoading;
  @override
  bool get isBalanceHistoryLoading;
  @override
  bool get isLoadingSessions;
  @override
  bool get isDeletingSession;
  @override
  bool get textFieldDisability;
  @override
  bool get isPinCodeEnabled;
  @override // PIN kod yoqilganmi
  bool get isBiometricEnabled;
  @override // Biometrik kirish yoqilganmi
  bool get hasSellerBalance;
  @override
  String get errorMessage;
  @override
  String get paymentService;
  @override
  String get paymentService2;
  @override
  int get index;
  @override
  int get subTabIndex;
  @override
  int get smsTariffID;
  @override
  int get nextPage;
  @override
  int get oneDollarInSum;
  @override
  ProfileUpdateResponse? get updateData;
  @override
  UserInfoResponse? get userInfoData;
  @override // Owner of the seller's currently-attached shop. Populated only
// when the logged-in user is a seller (Profil tab renders this in
// place of the seller's own name/phone/avatar).
  SellerOwnerResponse? get sellerOwnerData;
  @override
  AppVersionResponse? get appVersionData;
  @override
  CreateUserReferralResponse? get createUserReferralData;
  @override
  InvitedUsersResponse? get invitedUsersData;
  @override
  InvitedUsersResponse? get paidUsersData;
  @override
  MakePaymentResponse? get paymentSMSUrl;
  @override
  SmsTariffsResponse? get smsTariffs;
  @override
  ReferralBonusResponse? get balanceHistory;
  @override
  SmsHistoryResponse? get smsHistory;
  @override
  MySmsHistoryResponse? get mySmsHistory;
  @override
  SmsUsageSummaryResponse? get smsUsageSummary;
  @override
  InviteHistoryResponse? get invitedHistory;
  @override
  SendInviteLinkResponse? get sendInviteLink;
  @override
  GetSmsCountPriceResponse? get smsCountPrice;
  @override
  TopUpUserBalanceResponse? get topUpUserBalanceLink;
  @override // Null = not yet attempted; true = auto-launch succeeded; false =
// every fallback failed. Drives the status banner above the
// "Open in browser" button in the top-up bottom sheet so users
// can see whether anything happened automatically.
  bool? get lastPaymentLaunchSucceeded;
  @override
  WalletBalanceResponse? get walletBalance;
  @override
  WalletBalanceSummaryResponse? get walletBalanceSummary;
  @override
  bool get isWalletBalanceSummaryLoading;
  @override
  SessionsResponse? get sessionsData;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  File? get selectedImageFile;
  @override
  @JsonKey(ignore: true)
  _$$ProfileStateImplCopyWith<_$ProfileStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

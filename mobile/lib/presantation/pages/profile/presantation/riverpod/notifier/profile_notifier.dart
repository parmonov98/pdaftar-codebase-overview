import 'dart:developer';

import 'package:pdaftaruz/core/storage/accounts/account_switcher.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/top_up_user_balance_response.dart';
import 'package:pdaftaruz/presantation/pages/applications/data/sms_tariffs_response.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/widgets/wallet_balance_response.dart';
import 'package:overlay_kit/overlay_kit.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/my_sms_history_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sms_usage_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/wallet_balance_summary_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/user_info_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/payment_providers_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/profile_update_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/seller_owner_response.dart';
import 'package:pdaftaruz/presantation/pages/profile/data/sessions_response.dart';
import 'package:pdaftaruz/service/clarity/clarity_analytics.dart';
import 'package:pdaftaruz/service/clarity/clarity_events.dart';
import 'package:pdaftaruz/service/clarity/clarity_transaction_analytics.dart';
import 'package:pdaftaruz/service/clarity/clarity_wallet_topup.dart';
import 'package:pdaftaruz/service/google_sign_in/google_sign_in_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import '../../../../../../core/handlers/http_service.dart';
import '../../../../../../injection.dart';
import '../../../../instalments/data/get_currency_rate_model.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  int _smsPriceRequestId = 0;
  int? _quotedSmsQuantity;
  final ProfileRepository _profileRepository;
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  ProfileNotifier(this._profileRepository) : super(const ProfileState());

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmationController =
      TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController referralCodeController = TextEditingController();
  final TextEditingController smsCountController = TextEditingController();
  final TextEditingController inviteLinkController = TextEditingController();
  final TextEditingController userBalanceController = TextEditingController();

  // Payment providers loaded from API
  List<PaymentProvider> paymentProviders = [];

  Future<void> loadPaymentProviders() async {
    try {
      final response = await _profileRepository.getPaymentProviders();
      response.when(
        success: (data) {
          final providersResponse = data as PaymentProvidersResponse;
          paymentProviders =
              providersResponse.data.where((p) => p.isEnabled).toList();

          // Set default payment option if available
          final def = paymentProviders.firstWhere(
            (p) => p.isDefault,
            orElse: () => paymentProviders.isNotEmpty
                ? paymentProviders.first
                : PaymentProvider(
                    id: 0,
                    name: 'Wallet',
                    code: state.paymentService2,
                    isEnabled: true,
                    isDefault: false,
                  ),
          );
          if (def.code.isNotEmpty) {
            state = state.copyWith(paymentService2: def.code);
          }
        },
        failure: (failure, status, errorMessage) {
          debugPrint('==> load payment providers failure: $failure');
        },
      );
    } catch (e) {
      debugPrint('==> load payment providers exception: $e');
    }
  }

  Future<void> refreshReferralPage(int index) async {
    if (index == 0) {
      await getPaidUsers();
    } else {
      await getBalanceHistory();
    }
  }

  Future refreshAccount() async {
    await getUserInfo(forceRefresh: true);
    await getWalletBalance();
    await loadPaymentProviders();
    // The full list only when it is already on screen somewhere; the
    // Profil card needs just the total.
    if (state.balanceHistory != null) {
      await getBalanceHistory(isRefresh: true);
    } else {
      await getReferralBalance();
    }
    // Refresh the seller's owner alongside the rest. No-op for owners
    // (endpoint 404s and we leave state.sellerOwnerData alone).
    await getSellerOwner();
  }

  /// Fetches GET /api/mobile/seller/my-owner and stores the response
  /// on `state.sellerOwnerData`. Best-effort: owners get a 404 here
  /// (they're not sellers) and we silently keep `sellerOwnerData=null`
  /// so the UI falls back to the user's own identity, which is the
  /// correct behavior on owner accounts.
  Future<void> getSellerOwner() async {
    try {
      final response = await _profileRepository.getSellerOwner();
      response.when(
        success: (data) {
          if (!mounted) return;
          if (data is SellerOwnerResponse) {
            state = state.copyWith(sellerOwnerData: data);
          }
        },
        failure: (_, statusCode, ___) {
          // 404 = owner account (no SELLER user_shops row). Leave the
          // existing sellerOwnerData untouched so a stale-but-correct
          // value still shows on transient errors.
          if (statusCode == 404 && mounted) {
            state = state.copyWith(sellerOwnerData: null);
          }
        },
      );
    } catch (e) {
      debugPrint('==> getSellerOwner threw: $e');
    }
  }

  /// Leaves [shopId] as a seller (#543). Returns null on success, else the
  /// server's message (or an empty string when there is none).
  Future<String?> leaveBusiness(int shopId) async {
    final response = await _profileRepository.leaveShop(shopId: shopId);
    return response.when(
      success: (_) => null,
      failure: (_, __, message) => message is String ? message : '',
    );
  }

  Future toggleNotification(bool isOn) async {
    state = state.copyWith(isNotificationOn: isOn);
  }

  void referralTextFieldDisability(bool value) {
    if (value == true && inviteLinkController.text.length == 12) {
      state = state.copyWith(textFieldDisability: false);
    } else if (value == false && referralCodeController.text.isNotEmpty) {
      state = state.copyWith(textFieldDisability: false);
    } else {
      state = state.copyWith(textFieldDisability: true);
    }
  }

  List<String> buildTabs(BuildContext context) {
    return [
      AppLocalization.getText(context)?.monthly_sub ?? 'Monthly',
      AppLocalization.getText(context)?.annual_sub ?? 'Annual',
    ];
  }

  List<String> buildOuterTabs(BuildContext context) {
    return [
      AppLocalization.getText(context)?.invite_users ?? 'Invite Users',
      AppLocalization.getText(context)?.balance_history ?? 'Balance History',
    ];
  }

  List<String> buildInnerTabs(BuildContext context) {
    return [
      AppLocalization.getText(context)?.invited_users ?? 'Invited Users',
      AppLocalization.getText(context)?.paid_users ?? 'Paid Users',
    ];
  }

  void restoreSetting() {
    // Track logout with Mixpanel
    try {
      MixpanelAnalyticsService.instance.track(MixpanelEvents.logout);
      MixpanelAnalyticsService.instance.reset();
    } catch (_) {}

    final lang = LocalStorage.instance.getLang();
    final theme = LocalStorage.instance.getTheme();
    final domain = LocalStorage.instance.getDomain();
    final docsAcceptance = LocalStorage.instance.getAcceptanceDocs();

    LocalStorage.instance.logout();

    LocalStorage.instance.setLang(lang);
    LocalStorage.instance.setTheme(theme);
    LocalStorage.instance.setDomain(domain);
    LocalStorage.instance.setAcceptanceDocs(docsAcceptance);
  }

  /// TODO: placeholder counts. These two literals are rendered as badge
  /// numbers on the Subscriptions page, so users currently see "12" and
  /// "34" regardless of their account.
  List<int> tabsBadges() {
    return [12, 34];
  }

  void changeTab({
    required int index,
  }) {
    state = state.copyWith(nextPage: index);
  }

  Future<void> update(
      {VoidCallback? checkYourNetwork,
      VoidCallback? unAuthorised,
      VoidCallback? success,
      required int userId,
      required BuildContext context,
      File? imagePath
      // required WidgetRef ref
      }) async {
    state = state.copyWith(
      isUpdateLoading: true,
    );

    final response = await _profileRepository.update(
      name: nameController.text,
      //email: emailController.text,
      imagePath: imagePath,
      userId: userId,
      phoneNumber:
          phoneController.text.replaceAll(RegExp(r'[-()\s]'), "").reFormat,
    );
    response.when(
      success: (data) async {
        state = state.copyWith(isUpdateLoading: false, updateData: data);

        nameController.text = "";
        //emailController.text = "";
        phoneController.text = "";

        // Track profile updated with Mixpanel
        try {
          MixpanelAnalyticsService.instance
              .track(MixpanelEvents.profileUpdated);
        } catch (_) {}

        success?.call();
        AppHelpers.showSnackBarSuccess(
            message: AppLocalization.getText(context)
                    ?.request_completed_successfully ??
                "");
        await getUserInfo();
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isUpdateLoading: false, isError: true);
        AppHelpers.showSnackBarError(errorMessage: errorMessage);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> update profile failure: $failure');
      },
    );
  }

  Future<void> changePasswordOwner(
      {VoidCallback? checkYourNetwork,
      VoidCallback? unAuthorised,
      VoidCallback? success,
      required int userId,
      required BuildContext context}) async {
    state = state.copyWith(
      isUpdateLoading: true,
    );
    if (passwordController.text.isNotEmpty &&
        passwordConfirmationController.text.isNotEmpty &&
        oldPasswordController.text.isNotEmpty) {
      final response = await _profileRepository.changePassword(
        password: passwordController.text,
        passwordConfirmation: passwordConfirmationController.text,
        userId: userId,
        oldPassword: oldPasswordController.text,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isUpdateLoading: false, updateData: data);

          // ref.read(homeProvider.notifier).getUserShops();
          passwordController.text = "";
          passwordConfirmationController.text = "";
          oldPasswordController.text = "";
          success?.call();
          AppHelpers.showSnackBarSuccess(
              message: AppLocalization.getText(context)
                      ?.request_completed_successfully ??
                  "");
        },
        failure: (failure, status, errorMessage) {
          state = state.copyWith(
              isUpdateLoading: false,
              isError: true,
              errorMessage: errorMessage);
          AppHelpers.showSnackBarError(errorMessage: errorMessage);

          if (failure == const NetworkExceptions.unauthorisedRequest()) {
            unAuthorised?.call();
          }
          debugPrint('==> Change password failure: $failure');
        },
      );
    } else if (oldPasswordController.text.isEmpty) {
      state = state.copyWith(
          isUpdateLoading: false,
          isError: true,
          errorMessage: "Required old password");
    } else if (passwordController.text.isEmpty) {
      state = state.copyWith(
          isUpdateLoading: false,
          isError: true,
          errorMessage: "Required new password");
    } else if (passwordConfirmationController.text.isEmpty) {
      state = state.copyWith(
          isUpdateLoading: false,
          isError: true,
          errorMessage: "Required confirmation password");
    }
  }

  Future<void> getUserInfo({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    bool forceRefresh = false,
  }) async {
    // If data already exists and not refreshing, don't reload
    if (!forceRefresh && state.userInfoData != null) {
      success?.call();
      return;
    }

    if (forceRefresh) ProfileRepositoryImpl.forgetUserInfo();
    state = state.copyWith(
      isUpdateLoading: true,
    );

    final response = await _profileRepository.getUserInfo();
    response.when(
      success: (data) async {
        UserInfoResponse user = data;
        // Single emission: userInfoData and the seller-balance flag land
        // together. The old code emitted twice back-to-back for sellers,
        // so every watcher rebuilt twice per fetch. Owners keep the
        // previous hasSellerBalance value, exactly as before.
        final isSeller = user.userType != null && user.userType != "OWNER";
        state = state.copyWith(
          isUpdateLoading: false,
          userInfoData: data,
          hasSellerBalance: isSeller
              ? (user.data?.isSellerActive ?? false)
              : state.hasSellerBalance,
        );

        // Null safety check'lar (Android uchun ham)
        if (data.data?.id != null) {
          await LocalStorage.instance.setID(data.data!.id);
        }
        //await LocalStorage.instance.setEmail(data.data?.email);
        if (data.data?.name != null) {
          await LocalStorage.instance.setUserName(data.data!.name!);
        }
        if (data.data?.phoneNumber != null) {
          await LocalStorage.instance.setPhoneNumber(data.data!.phoneNumber!);
        }

        final userName = LocalStorage.instance.getUserName();
        final phoneNumber = LocalStorage.instance.getPhoneNumber();

        nameController.text = userName.isNotEmpty ? userName : "";
        //emailController.text = LocalStorage.instance.getEmail();
        phoneController.text = phoneNumber.isNotEmpty
            ? phoneNumber.format.replaceAll("+998 ", "")
            : "";
        success?.call();
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isError: true, isUpdateLoading: false);

        // Error message ko'rsatish (try-catch bilan)
        try {
          // Internet yo'qligi yoki unauthorised bo'lsa, error message ko'rsatmaslik
          final isNoInternet =
              failure == const NetworkExceptions.noInternetConnection();
          final isUnauthorised =
              failure == const NetworkExceptions.unauthorisedRequest();

          if (!isNoInternet && !isUnauthorised) {
            try {
              final errorMsg = NetworkExceptions.getErrorMessage(failure);
              if (errorMsg.isNotEmpty) {
                AppHelpers.showSnackBarError(
                  errorMessage: errorMsg,
                );
              }
            } catch (e) {
              debugPrint('==> Error showing snackbar in getUserInfo: $e');
            }
          }
        } catch (e) {
          debugPrint('==> Error in getUserInfo failure handler: $e');
        }

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> update profile failure: $failure');
      },
    );
  }

  ProfileState changeTabIndex({required int index}) => state = state.copyWith(index: index);

  ProfileState changeSubTabIndex({required int index}) =>
      state = state.copyWith(subTabIndex: index);

  void changePaymentService({required String value}) {
    state = state.copyWith(paymentService: value);
  }

  void changePaymentService2({required String value}) {
    state = state.copyWith(paymentService2: value);
  }

  void changeSMSTariff(int tariffId) {
    state = state.copyWith(smsTariffID: tariffId);
  }

  void setSelectedTariff(int? tariffId) {
    state = state.copyWith(smsTariffID: tariffId ?? 0);
  }

  // Функция для получения числа из форматированной строки
  int? parseFormattedNumber(String value) {
    if (value.isEmpty) return null;
    // Удаляем все пробелы из строки перед парсингом
    final cleanValue = value.replaceAll(' ', '');
    return int.tryParse(cleanValue);
  }

  int calculateSMSPrice() {
    if (state.smsTariffs?.smsTariffs == null ||
        state.smsTariffs!.smsTariffs!.isEmpty) {
      return 0;
    }

    final firstTariff = state.smsTariffs!.smsTariffs!.first;
    if (firstTariff.smsCount == null ||
        firstTariff.smsCount == 0 ||
        firstTariff.price == null) {
      return 0;
    }

    final value = firstTariff.price! / firstTariff.smsCount!;
    return value.toInt();
  }

  int calculateTotalPrice() {
    final smsCount = parseFormattedNumber(smsCountController.text) ?? 0;
    return smsCount * calculateSMSPrice();
  }

  Future<dynamic> buySMSTariffOrder({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required int? userID,
    required int? smsTariffID,
    required String? paySys,
    int? smsCount,
    required BuildContext context,
  }) async {
    if (context.mounted) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final sms = smsCount.toString().replaceAll(RegExp(r'[-()\s]'), '');

      ClarityAnalytics.instance.tag('payment_for', 'sms');
      ClarityAnalytics.instance.tag('payment_provider', paySys ?? '');

      final response = await _profileRepository.buySMSTariffOrder(
          userID: userID ?? 0,
          smsTariffID: smsTariffID ?? 0,
          paySys: paySys ?? "",
          smsCount: int.tryParse(sms));

      response.when(success: (data) async {
        state = state.copyWith(isLoading: false, paymentSMSUrl: data);
        success?.call();

        if (state.paymentSMSUrl?.link != null) {
          final smsLinkUri = Uri.parse("${state.paymentSMSUrl?.link}");
          if (await canLaunchUrl(smsLinkUri)) {
            await launchUrl(smsLinkUri, mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch ${state.paymentSMSUrl?.link}';
          }
        } else if (state.paymentService == "referal_balance") {
          ClarityAnalytics.instance.event(ClarityEvents.paymentSucceeded);
          AppNavigator.pop();
          Future.delayed(const Duration(milliseconds: 300)).then((value) {
            AppNavigator.pop();
          });
        } else {
          // wallet path: synchronous debit, no provider redirect
          ClarityAnalytics.instance.event(ClarityEvents.paymentSucceeded);
        }
      }, failure: (failure, status, data) {
        state = state.copyWith(isLoading: false);
        ClarityAnalytics.instance.event(ClarityEvents.paymentFailed);
        // ApiResult's third failure argument is parsed response data, not
        // the backend message. messageConverter stores that message in the
        // NetworkExceptions value instead.
        final message = NetworkExceptions.getErrorMessage(failure);
        if (message.isNotEmpty) {
          AppHelpers.showSnackBarError(errorMessage: message);
        }
        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint("==> Buy SMS tariff failure: $failure");
      });
    } catch (e) {
      state = state.copyWith(isLoading: false);
      AppHelpers.showSnackBarError(errorMessage: e.toString());
    }
  }

  Future<void> getSMSTariffs({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getSMSTariffs();
    response.when(
      success: (data) async {
        final tariffsData = data as SmsTariffsResponse;
        if (tariffsData.smsTariffs != null) {
          tariffsData.smsTariffs!.sort((SmsTariff a, SmsTariff b) =>
              (a.smsCount ?? 0).compareTo(b.smsCount ?? 0));
        }
        // Default "Free 50" (id: 13) ni tanlash, agar topilmasa sms_count >= 10 bo'lgan birinchi tarifni tanlash
        int defaultTariffId = 0;
        if (tariffsData.smsTariffs?.isNotEmpty == true) {
          // Avval "Free 50" (id: 13) ni qidirish
          try {
            final free50Tariff = tariffsData.smsTariffs!.firstWhere(
              (SmsTariff tariff) => tariff.id == 13,
            );
            defaultTariffId = free50Tariff.id ?? 0;
          } catch (e) {
            // Agar "Free 50" topilmasa, sms_count >= 10 bo'lgan birinchi tarifni tanlash
            final filteredTariffs = tariffsData.smsTariffs!
                .where((SmsTariff tariff) => (tariff.smsCount ?? 0) >= 10)
                .toList();
            if (filteredTariffs.isNotEmpty) {
              defaultTariffId = filteredTariffs.first.id ?? 0;
            } else if (tariffsData.smsTariffs!.isNotEmpty) {
              // Agar sms_count >= 10 bo'lgan tariflar bo'lmasa, birinchi tarifni tanlash
              defaultTariffId = tariffsData.smsTariffs!.first.id ?? 0;
            }
          }
        }
        state = state.copyWith(
          isLoading: false,
          smsTariffs: tariffsData,
          smsTariffID: defaultTariffId,
        );
        success?.call();
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isError: true, isLoading: false);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        } else {
          final errorMsg = NetworkExceptions.getErrorMessage(failure);
          if (errorMsg.isNotEmpty) {
            AppHelpers.showSnackBarError(errorMessage: errorMsg);
          }
        }
        debugPrint('==> get sms tariffs failure: $failure');
      },
    );
  }

  bool hasSmsPriceForQuantity(int quantity) =>
      state.smsCountPrice?.totalPrice != null && _quotedSmsQuantity == quantity;

  Future<bool> getSmsCountPrice({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    final requestId = ++_smsPriceRequestId;
    state = state.copyWith(isLoading: true);
    final smsQty = smsCountController.text.replaceAll(" ", '');
    final quantity = int.tryParse(smsQty) ?? 0;
    final response = await _profileRepository.getSmsCountPrice(
        smsQty: quantity);
    var ready = false;
    response.when(
      success: (data) async {
        if (requestId != _smsPriceRequestId) return;
        if ((int.tryParse(smsCountController.text.replaceAll(" ", '')) ?? 0) !=
            quantity) {
          state = state.copyWith(isLoading: false, smsCountPrice: null);
          _quotedSmsQuantity = null;
          return;
        }
        _quotedSmsQuantity = quantity;
        state = state.copyWith(isLoading: false, smsCountPrice: data);
        ready = state.smsCountPrice?.totalPrice != null;
        success?.call();
      },
      failure: (failure, status, errorMessage) {
        if (requestId != _smsPriceRequestId) return;
        state = state.copyWith(isError: true, isLoading: false);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> get calculated sms price failure: $failure');
      },
    );
    return ready;
  }

  void clearSmsCountPrice() {
    _smsPriceRequestId++;
    _quotedSmsQuantity = null;
    state = state.copyWith(isLoading: false, smsCountPrice: null);
  }

  Future<void> getInvitedUsers({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getInvitedUsers();

    response.when(success: (data) {
      state = state.copyWith(isLoading: false, invitedUsersData: data);
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false, isError: true);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint(
          '==> get invited users through referral code failure: $failure');
    });
  }

  Future<void> getPaidUsers({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getPaidUsers();

    response.when(success: (data) {
      state = state.copyWith(isLoading: false, paidUsersData: data);
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false, isError: true);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint('==> get paid users through referral code failure: $failure');
    });
  }

  Future<void> createUserReferralCode(
      {VoidCallback? checkYourNetwork,
      VoidCallback? unAuthorised,
      VoidCallback? success,
      BuildContext? context,
      required String referralCode,
      required int userID}) async {
    state = state.copyWith(isLoading: true);
    final response = await _profileRepository.createUserReferral(
        referralCode: referralCode.toUpperCase(), userID: userID);
    response.when(success: (data) {
      state = state.copyWith(isLoading: false, createUserReferralData: data);
      AppHelpers.showSnackBarSuccess(
          message:
              "${AppLocalization.getText(context)?.referral_code_created}: ${referralCodeController.text}");
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isError: true, isLoading: false);
      AppHelpers.showSnackBarError(errorMessage: "$errorMessage");

      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> create user referral code: $failure");
    });
  }

  Future<void> getBalanceHistory({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
    bool isRefresh = false,
  }) async {
    // Agar ma'lumotlar allaqachon mavjud bo'lsa va refresh emas bo'lsa, qayta yuklamaslik
    if (!isRefresh && state.balanceHistory != null) {
      success?.call();
      return;
    }

    state = state.copyWith(isBalanceHistoryLoading: true);

    final response = await _profileRepository.getBalanceHistory();
    response.when(success: (data) async {
      state =
          state.copyWith(isBalanceHistoryLoading: false, balanceHistory: data);
      await LocalStorage.instance
          .setReferralBalance(data.totalBalance.toString());
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isBalanceHistoryLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get balance history failure: $failure");
    });
  }

  /// The referral total alone, for cold start and the Profil card. The full
  /// history (`getBalanceHistory`) returns every referral row unpaginated —
  /// ~1.9 MB for a busy referrer — and only the history page needs it.
  /// Falls back to the full endpoint on a backend that predates the summary
  /// (it answers 405 there, not 404 — verified against the pre-#498 API).
  Future<void> getReferralBalance() async {
    if (state.isBalanceHistoryLoading) return;
    state = state.copyWith(isBalanceHistoryLoading: true);
    final response = await _profileRepository.getReferralTotal();
    var fallBack = false;
    await response.when(
      success: (total) async {
        await LocalStorage.instance.setReferralBalance(total.toString());
      },
      failure: (failure, status, _) async {
        // A backend without the summary answers 405 (another users/{…}
        // route matches the path) or 404. Nothing else: timeouts map to
        // 500 here, and a flaky network is the worst time for the full list.
        fallBack = status == 404 || status == 405;
      },
    );
    if (!mounted) return;
    // Toggled even on success so the Profil card, which falls back to the
    // stored total, rebuilds with it.
    state = state.copyWith(isBalanceHistoryLoading: false);
    if (fallBack) await getBalanceHistory(isRefresh: true);
  }

  Future<void> getSMSHistory({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getSMSHistory();
    response.when(success: (data) {
      state = state.copyWith(isLoading: false, smsHistory: data);
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get SMS history failure: $failure");
    });
  }

  Future<void> getMySmsHistory({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
    int? page,
    int? perPage,
    bool isRefresh = false,
  }) async {
    final requestedPage = page ?? 1;
    final isFirstPage = requestedPage == 1;

    // First page: short-circuit if we already have it cached. Subsequent
    // pages always need to hit the network so we can accumulate.
    if (!isRefresh && isFirstPage && state.mySmsHistory != null) {
      success?.call();
      return;
    }

    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getMySmsHistory(
      page: requestedPage,
      perPage: perPage ?? 10,
    );
    response.when(success: (data) {
      // Append on subsequent pages; replace on page 1 / refresh. Without
      // this, _loadMore() would clobber the visible list with just the
      // newest page each time and the user could never reach the end of
      // their SMS history.
      MySmsHistoryResponse merged;
      if (isFirstPage || isRefresh || state.mySmsHistory?.data == null) {
        merged = data;
      } else {
        final existing = state.mySmsHistory!.data!;
        final incoming = data.data ?? const <MySmsHistoryItem>[];
        // Drop dupes by id, just in case the backend overlaps pages.
        final seen = existing.map((e) => e.id).toSet();
        final additions = incoming.where((e) => !seen.contains(e.id));
        merged = MySmsHistoryResponse(
          success: data.success,
          data: [...existing, ...additions],
          pagination: data.pagination,
        );
      }
      state = state.copyWith(isLoading: false, mySmsHistory: merged);
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get my SMS history failure: $failure");
    });
  }

  /// Hits `/api/mobile/users/my-sms-usage-summary` and stores the result on
  /// state. The endpoint returns server-side aggregates so the SMS history
  /// page can render exact "current month / previous month" totals
  /// without depending on whatever pages the paginated list happens to
  /// have loaded.
  Future<void> getMySmsUsageSummary({
    bool isRefresh = false,
    String? period,
    VoidCallback? success,
  }) async {
    if (!isRefresh && period == null && state.smsUsageSummary != null) {
      success?.call();
      return;
    }
    final response =
        await _profileRepository.getMySmsUsageSummary(period: period);
    response.when(
      success: (data) {
        if (data is SmsUsageSummaryResponse) {
          state = state.copyWith(smsUsageSummary: data);
          success?.call();
        }
      },
      failure: (failure, status, errorMessage) {
        debugPrint("==> get my SMS usage summary failure: $failure");
      },
    );
  }

  Future<void> sendInviteLink({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
  }) async {
    final phone = normalizeUzbekReferralPhone(inviteLinkController.text);

    if (phone == null) {
      AppHelpers.showSnackBarInfo(
        message: context == null
            ? "Telefon raqami +998 bilan boshlanishi, to'g'ri formatda kiritilishi kerak"
            : (AppLocalization.getText(context)?.invalid_uzbek_phone_format ??
                "Telefon raqami +998 bilan boshlanishi, to'g'ri formatda kiritilishi kerak"),
      );
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final response =
          await _profileRepository.sendInviteLink(phoneNumber: phone);
      response.when(success: (data) {
        state = state.copyWith(isLoading: false, sendInviteLink: data);
        AppHelpers.showSnackBarSuccess(message: data.message);
        success?.call();
      }, failure: (failure, status, errorMessage) {
        state = state.copyWith(isLoading: false);
        AppHelpers.showSnackBarError(errorMessage: errorMessage.toString());
        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint("==> send invited link failure: $failure");
      });
    } catch (e) {
      state = state.copyWith(isLoading: false);
      AppHelpers.showSnackBarError(errorMessage: e.toString());
    }
  }

  Future<void> deleteUser({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required int? userID,
  }) async {
    state = state.copyWith(isDeleteUserLoading: true);
    final response = await _profileRepository.deleteUser(userID: userID);
    response.when(
      success: (data) async {
        state = state.copyWith(isDeleteUserLoading: false);
        // Only the open account was deleted (#542): with others on the
        // device the next one opens instead of the sign-in screen.
        if (await AccountSwitcher.maybeInstance?.onActiveDeleted() ?? false) {
          return;
        }
        LocalStorage.instance.logout();
        success?.call();
      },
      failure: (failure, status, data) {
        state = state.copyWith(isError: true, isDeleteUserLoading: false);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> update profile failure: $failure');
      },
    );
  }

  Future<void> topUpBalance({
    required int userId,
    required int amount,
    required String paySys,
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    AppHelpers.showLoadingAlert(context: context);
    // Clear last-launch outcome so the banner doesn't flash stale
    // status from a previous attempt while the new request is in
    // flight.
    state = state.copyWith(
      isLoading: true,
      lastPaymentLaunchSucceeded: null,
    );

    ClarityAnalytics.instance.tag('payment_for', 'balance');
    ClarityAnalytics.instance.tag('payment_provider', paySys);

    final actor = ClarityTransactionAnalytics.instance.capture();
    final response = await _profileRepository.topUpBalance(
        userId: userId, amount: amount, paySys: paySys);
    response.when(success: (data) async {
      final action = ClarityWalletTopup.acceptedAction(paySys, data);
      if (action != null) {
        ClarityTransactionAnalytics.instance.observed(actor, action);
      }
      OverlayLoadingProgress.stop();
      state = state.copyWith(
          isLoading: false,
          topUpUserBalanceLink: TopUpUserBalanceResponse.fromJson(data));

      try {
        MixpanelAnalyticsService.instance.track(MixpanelEvents.balanceToppedUp,
            {'provider': paySys, 'amount': amount});
      } catch (_) {}
      success?.call();
      if (state.topUpUserBalanceLink?.link != null) {
        await _launchPaymentLink(state.topUpUserBalanceLink!.link!);
      }
    }, failure: (failure, status, data) {
      ClarityTransactionAnalytics.instance.observed(actor, ClarityObservedAction.walletTopupFailed);
      OverlayLoadingProgress.stop();
      state = state.copyWith(isLoading: false);
      AppHelpers.showSnackBarError(errorMessage: failure.toString());
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint('==> top up balance response failure: $failure');
    });
  }

  /// Re-launches the payment link without re-creating it. The bottom
  /// sheet exposes a "Brauzerda ochish" (Open in browser) button after
  /// link creation so users on devices where the auto-launch silently
  /// failed (Honor MagicOS, MIUI, EMUI — see comment in topUpBalance)
  /// can retry manually. Same fallback cascade as the auto-path.
  Future<void> relaunchPaymentLink() async {
    final link = state.topUpUserBalanceLink?.link;
    if (link == null || link.isEmpty) return;
    await _launchPaymentLink(link);
  }

  /// Shared launcher: try external app → in-app browser → platform
  /// default. We deliberately skip `canLaunchUrl` because OEM skins
  /// (Honor MagicOS, MIUI/HyperOS, EMUI) return false-negative even
  /// for valid `https://` URLs.
  ///
  /// Records the outcome on state so the bottom sheet's status banner
  /// can render correctly — green "Link ochildi" on success, amber
  /// "Avtomatik ochilmadi" on failure. Either way the "Open in
  /// browser" button stays visible so the user can retry.
  Future<void> _launchPaymentLink(String link) async {
    final linkUri = Uri.parse(link);

    Future<bool> tryLaunch(LaunchMode mode) async {
      try {
        return await launchUrl(linkUri, mode: mode);
      } catch (e) {
        debugPrint('==> launchUrl($mode) failed: $e');
        return false;
      }
    }

    final ok = (await tryLaunch(LaunchMode.externalApplication)) ||
        (await tryLaunch(LaunchMode.inAppBrowserView)) ||
        (await tryLaunch(LaunchMode.platformDefault));

    state = state.copyWith(lastPaymentLaunchSucceeded: ok);

    if (!ok) {
      AppHelpers.showSnackBarError(
        errorMessage:
            "To'lov linkini ochib bo'lmadi. Iltimos, qayta urinib ko'ring.",
      );
    }
  }

  /// Clears the cached payment link so the "Open in browser" button
  /// disappears when the modal reopens. Called when the user changes
  /// the amount or selects a different provider.
  void clearPaymentLink() {
    state = state.copyWith(topUpUserBalanceLink: null);
  }

  Future<void> getAppVersion({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    // The store version is static for the lifetime of the process — one
    // fetch per session is enough. Without this guard every re-init of
    // the Profil menu refetched it and flipped the shared isLoading flag,
    // notifying every whole-state watcher of profileProvider twice.
    if (state.appVersionData != null) {
      success?.call();
      return;
    }
    state = state.copyWith(isLoading: true);
    final response = await _profileRepository.getAppVersion();
    response.when(success: (data) async {
      state = state.copyWith(isLoading: false, appVersionData: data);
      success?.call();
    }, failure: (failure, status, data) {
      state = state.copyWith(isError: true, isLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get app version failure $failure");
    });
  }

  Future<void> getWalletBalance({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
  }) async {
    state = state.copyWith(isLoading: true);

    final response = await _profileRepository.getWalletBalance();
    response.when(success: (data) {
      state = state.copyWith(isLoading: false, walletBalance: data);
      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get wallet balance failure: $failure");
    });
  }

  Future<void> getWalletBalanceHistory({
    int? page,
    bool isRefresh = false,
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    BuildContext? context,
  }) async {
    if (isRefresh || page == null || page == 1) {
      // Initial load or refresh - use isLoading
      state = state.copyWith(isLoading: true, isBalanceHistoryLoading: false);
    } else {
      // Pagination - use isBalanceHistoryLoading
      state = state.copyWith(isBalanceHistoryLoading: true);
    }

    final response =
        await _profileRepository.getWalletBalanceHistory(page: page);
    response.when(success: (data) {
      WalletBalanceResponse newData = data;

      if (isRefresh || page == null || page == 1) {
        // Refresh or first page - replace data
        state = state.copyWith(
            isLoading: false,
            isBalanceHistoryLoading: false,
            walletBalance: newData);
      } else {
        // Pagination - append data
        final currentHistory = state.walletBalance?.history;
        if (currentHistory != null && newData.history != null) {
          final existingData =
              List<WalletBalanceDatum>.from(currentHistory.data ?? []);
          final newHistoryData = newData.history!.data ?? [];

          // Prevent duplicates
          for (var newItem in newHistoryData) {
            if (!existingData.any((existing) => existing.id == newItem.id)) {
              existingData.add(newItem);
            }
          }

          // Create updated history
          final updatedHistory = History(
            currentPage: newData.history?.currentPage,
            data: existingData,
            firstPageUrl: newData.history?.firstPageUrl,
            from: newData.history?.from,
            lastPage: newData.history?.lastPage,
            lastPageUrl: newData.history?.lastPageUrl,
            links: newData.history?.links,
            nextPageUrl: newData.history?.nextPageUrl,
            path: newData.history?.path,
            perPage: newData.history?.perPage,
            prevPageUrl: newData.history?.prevPageUrl,
            to: newData.history?.to,
            total: newData.history?.total,
          );

          final updatedWalletBalance = WalletBalanceResponse(
            totalWalletBalance: newData.totalWalletBalance,
            history: updatedHistory,
          );

          state = state.copyWith(
              isLoading: false,
              isBalanceHistoryLoading: false,
              walletBalance: updatedWalletBalance);
        } else {
          state = state.copyWith(
              isLoading: false,
              isBalanceHistoryLoading: false,
              walletBalance: newData);
        }
      }

      success?.call();
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isLoading: false, isBalanceHistoryLoading: false);
      if (failure == const NetworkExceptions.unauthorisedRequest()) {
        unAuthorised?.call();
      }
      debugPrint("==> get wallet balance history failure: $failure");
    });
  }

  Future<void> getWalletBalanceSummary({required String period}) async {
    state = state.copyWith(isWalletBalanceSummaryLoading: true);
    final response =
        await _profileRepository.getWalletBalanceSummary(period: period);
    response.when(success: (data) {
      state = state.copyWith(
        isWalletBalanceSummaryLoading: false,
        walletBalanceSummary: data as WalletBalanceSummaryResponse,
      );
    }, failure: (failure, status, errorMessage) {
      state = state.copyWith(isWalletBalanceSummaryLoading: false);
      debugPrint("==> get wallet balance summary failure: $failure");
    });
  }

  Future<void> getOneDollar() async {
    try {
      final client = inject<HttpService>().client();
      final response = await client
          .get("api/mobile/currency/convert?from=usd&to=uzs&amount=1");
      final res = GetCurrencyRate.fromJson(response.data);
      log(res.toString());
      state = state.copyWith(oneDollarInSum: res.convertedAmount.toInt());
    } catch (e) {
      return;
    }
  }

  Future<void> switchPINCode({required bool value}) async {
    log(value.toString());
    if (value) {
      // The switch shows what is stored, never the tap: leaving the set-PIN
      // page without confirming a PIN (back button, edge swipe) must leave
      // it off (Trello #708).
      await openSetPinCodePage();
      await refreshPinCodeEnabled();
    } else {
      state = state.copyWith(
        isPinCodeEnabled: false,
      );
      LocalStorage.instance.writePINCodeEnableOrDisable(false);
      await LocalStorage.instance.clearPinData();
    }
  }

  Future<void> openSetPinCodePage() => AppNavigator.push(const SetPinCodeRoute());

  /// On only when a PIN is actually saved — the flag alone can be stale.
  Future<void> refreshPinCodeEnabled() async {
    final enabled = LocalStorage.instance.readPINCodeEnableOrDisable() &&
        await LocalStorage.instance.hasPinCode();
    if (!mounted) return;
    state = state.copyWith(isPinCodeEnabled: enabled);
  }

  void initPinKey() {
    // Synchronous LocalStorage read — one state emission, not three
    // (the isLoading true/false pair notified every whole-state watcher
    // twice for no visible change).
    state = state.copyWith(
        isPinCodeEnabled: LocalStorage.instance.readPINCodeEnableOrDisable());
  }

  // Tanlangan rasmni state ga saqlash
  void setSelectedImage(File? imageFile) {
    state = state.copyWith(selectedImageFile: imageFile);
  }

  // Tanlangan rasmni tozalash
  void clearSelectedImage() {
    state = state.copyWith(selectedImageFile: null);
  }

  // Telefon raqamini yangilash (verification kerak bo'lishi mumkin)
  Future<void> updatePhoneNumber({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required int userId,
    required BuildContext context,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isUpdateLoading: true);

    // Name is deliberately not sent from here. This runs on the
    // post-signup phone gate, where the profile has not been fetched yet
    // and nameController is empty — so the old fallback resolved to "" and
    // the server rejected the whole request as a missing required name.
    // Omitting it leaves the name the user already has.
    final response = await _profileRepository.update(
      imagePath: null,
      userId: userId,
      phoneNumber: phoneNumber,
    );

    response.when(
      success: (data) async {
        state = state.copyWith(isUpdateLoading: false, updateData: data);

        final updateResponse = data as ProfileUpdateResponse;

        // Agar verification kerak bo'lsa, success callback chaqiriladi va OTP sahifasiga o'tiladi
        if (updateResponse.requiresVerification == true) {
          success?.call();
        } else {
          // Agar verification kerak bo'lmasa, telefonni saqlash va getUserInfo chaqirish
          if (updateResponse.message != null) {
            AppHelpers.showSnackBarSuccess(message: updateResponse.message!);
          }
          await getUserInfo();
          success?.call();
        }
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isUpdateLoading: false, isError: true);
        AppHelpers.showSnackBarError(errorMessage: errorMessage);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> update phone number failure: $failure');
      },
    );
  }

  // OTP orqali telefonni tasdiqlash
  Future<void> verifyPhoneNumber({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required int userId,
    required BuildContext context,
    required String otp,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isUpdateLoading: true);

    final response = await _profileRepository.verifyPhone(
      userId: userId,
      otp: otp,
    );

    response.when(
      success: (data) async {
        state = state.copyWith(isUpdateLoading: false);

        // Telefonni local storage'ga saqlash
        await LocalStorage.instance.setPhoneNumber(phoneNumber);

        // User ma'lumotlarini yangilash
        await getUserInfo();

        if (!context.mounted) return;
        AppHelpers.showSnackBarSuccess(
          message: AppLocalization.getText(context)
                  ?.request_completed_successfully ??
              "Telefon raqami muvaffaqiyatli tasdiqlandi",
        );

        success?.call();
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isUpdateLoading: false, isError: true);
        AppHelpers.showSnackBarError(errorMessage: errorMessage);

        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> verify phone number failure: $failure');
      },
    );
  }

  Future<void> linkGoogleAccount({
    VoidCallback? success,
    VoidCallback? unAuthorised,
    Function(String errorMessage)? failure,
  }) async {
    try {
      // Step 1: Sign in with Google and get Firebase ID token
      final firebaseIdToken = await _googleSignInService.signInWithGoogle();

      if (firebaseIdToken == null) {
        // User cancelled the sign-in
        return;
      }

      // Step 2: Send Firebase ID token to backend
      final response = await _profileRepository.linkGoogleAccount(
        firebaseIdToken: firebaseIdToken,
      );

      response.when(
        success: (data) async {
          // Refresh user info to get updated Google account status
          await getUserInfo(success: () {
            success?.call();
            AppHelpers.showSnackBarSuccess(
              message: "Google Account muvaffaqiyatli ulandi",
            );
          });
        },
        failure: (failureError, status, errorMessage) {
          if (failureError == const NetworkExceptions.unauthorisedRequest()) {
            unAuthorised?.call();
          }
          failure?.call(
              errorMessage ?? "Google Account'ni ulashda xatolik yuz berdi");
          AppHelpers.showSnackBarError(errorMessage: errorMessage);
          debugPrint('==> link google account failure: $failureError');
        },
      );
    } catch (e) {
      debugPrint('==> link google account error: $e');
      failure?.call("Google Account'ni ulashda xatolik yuz berdi");
      AppHelpers.showSnackBarError(
          errorMessage: "Google Account'ni ulashda xatolik yuz berdi");
    }
  }

  Future<void> getSessions({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
  }) async {
    state = state.copyWith(isLoadingSessions: true, isError: false);

    final response = await _profileRepository.getSessions();
    response.when(
      success: (data) {
        state = state.copyWith(
          isLoadingSessions: false,
          sessionsData: data as SessionsResponse,
        );
        success?.call();
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isLoadingSessions: false, isError: true);
        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> get sessions failure: $failure');
      },
    );
  }

  Future<void> deleteAllSessions({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required BuildContext context,
  }) async {
    AppHelpers.showLoadingAlert(context: context);
    state = state.copyWith(isDeletingSession: true);

    final response = await _profileRepository.deleteAllSessions();
    response.when(
      success: (data) async {
        state = state.copyWith(isDeletingSession: false);
        OverlayLoadingProgress.stop();
        AppNavigator.pop();
        await Future.delayed(const Duration(milliseconds: 500));
        await getSessions(success: () {
          AppHelpers.showSnackBarSuccess(
            message: "Barcha qurilmalar muvaffaqiyatli o'chirildi",
          );
          success?.call();
        });
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isDeletingSession: false);
        OverlayLoadingProgress.stop();
        AppNavigator.pop();
        AppHelpers.showSnackBarError(errorMessage: errorMessage);
        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> delete all sessions failure: $failure');
      },
    );
  }

  Future<void> deleteSession({
    VoidCallback? checkYourNetwork,
    VoidCallback? unAuthorised,
    VoidCallback? success,
    required int sessionId,
    required BuildContext context,
  }) async {
    AppHelpers.showLoadingAlert(context: context);
    state = state.copyWith(isDeletingSession: true);

    final response =
        await _profileRepository.deleteSession(sessionId: sessionId);
    response.when(
      success: (data) async {
        state = state.copyWith(isDeletingSession: false);
        OverlayLoadingProgress.stop();
        AppNavigator.pop();
        await Future.delayed(const Duration(milliseconds: 500));
        await getSessions(success: () {
          AppHelpers.showSnackBarSuccess(
            message: "Qurilma muvaffaqiyatli o'chirildi",
          );
          success?.call();
        });
      },
      failure: (failure, status, errorMessage) {
        state = state.copyWith(isDeletingSession: false);
        OverlayLoadingProgress.stop();
        AppNavigator.pop();
        AppHelpers.showSnackBarError(errorMessage: errorMessage);
        if (failure == const NetworkExceptions.unauthorisedRequest()) {
          unAuthorised?.call();
        }
        debugPrint('==> delete session failure: $failure');
      },
    );
  }
}

enum InviteLinkFailureTone { info, error }

String? normalizeUzbekReferralPhone(String input) {
  final value = input.trim();
  if (value.isEmpty || !RegExp(r'^[+0-9\s()\-]+$').hasMatch(value)) {
    return null;
  }

  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) return digits;
  if (digits.length == 12 && digits.startsWith('998')) {
    return digits.substring(3);
  }
  return null;
}

InviteLinkFailureTone referralPhoneFailureTone(
    {required bool isLocalValidationFailure}) {
  return isLocalValidationFailure
      ? InviteLinkFailureTone.info
      : InviteLinkFailureTone.error;
}

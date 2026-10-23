import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/onboarding_quiz/onboarding_quiz_gate.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';

@RoutePage()
class PhoneEntryPage extends ConsumerStatefulWidget {
  /// When true this page is the mandatory post-signup phone-verify gate
  /// (Google sign-ups have no verified phone): back-dismiss is blocked, a
  /// "Later" escape hatch is shown, and success/skip continue into the app
  /// via [OnboardingQuizGate] instead of popping back to Profile settings.
  final bool isMandatoryGate;

  const PhoneEntryPage({super.key, this.isMandatoryGate = false});

  @override
  ConsumerState<PhoneEntryPage> createState() => _PhoneEntryPageState();
}

class _PhoneEntryPageState extends ConsumerState<PhoneEntryPage> {
  final TextEditingController phoneController = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  bool isValidPhoneNumber(String phone) {
    // Remove formatting and spaces
    String cleanNumber = phone.replaceAll(RegExp(r'[-()\s]'), '');
    // Check if it's a valid 9-digit Uzbekistan mobile number
    final RegExp regex =
        RegExp(r'^(90|91|93|94|95|97|98|99|50|88|77|33|20)[0-9]{7}$');
    return regex.hasMatch(cleanNumber);
  }

  String formatPhoneForSubmission(String phone) {
    // Remove any formatting
    String cleanNumber = phone.replaceAll(RegExp(r'[-()\s]'), '');
    return '+998$cleanNumber';
  }

  void _onContinue() {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() {
        errorText = AppLocalization.getText(context)?.this_field_is_mandatory;
      });
      return;
    }

    if (!isValidPhoneNumber(phone)) {
      setState(() {
        errorText = AppLocalization.getText(context)
                ?.sorry_an_unknown_error_occurred_please_try_again_later ??
            "Iltimos, to'g'ri telefon raqamini kiriting";
      });
      return;
    }

    setState(() {
      errorText = null;
    });

    final notifier = ref.read(profileProvider.notifier);
    final userId = LocalStorage.instance.getID();
    final formattedPhone = formatPhoneForSubmission(phone);

    notifier.updatePhoneNumber(
      context: context,
      userId: userId,
      phoneNumber: formattedPhone,
      success: () {
        try {
          MixpanelAnalyticsService.instance
              .track(MixpanelEvents.phoneChanged, {});
        } catch (_) {}
        // Navigate to OTP page for verification
        AppNavigator.push(
          OtpRoute(
            phoneNumber: phone,
            isForgotPassword: false,
            isPhoneVerification: true,
            isMandatoryGate: widget.isMandatoryGate,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return PopScope(
      // Mandatory gate: block the OS/back-gesture escape to home.
      canPop: !widget.isMandatoryGate,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(0, 0),
          child: AppBar(
            systemOverlayStyle:
                AppStatusBarThemes.changeDefaultThemeStatusBar(),
          ),
        ),
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.only(
              top: 0.00.sh,
              left: 12.0.w,
              right: 12.0.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Mandatory gate has no way back — hide the arrow so the
                    // only forward exits are "verify" or "Later".
                    widget.isMandatoryGate
                        ? const SizedBox(width: 40)
                        : InkWell(
                            borderRadius: BorderRadius.circular(1000),
                            onTap: () {
                              AppNavigator.pop();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: RotatedBox(
                                quarterTurns: 2,
                                child: CustomSvgWidgetAsset(
                                  Assets.arrowRightIconSvg,
                                  isFlag: false,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.color,
                                ),
                              ),
                            ),
                          ),
                    AppText(
                      "${AppLocalization.getText(context)?.phone_number}",
                      fontSize: 16.sp,
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                if (widget.isMandatoryGate) ...[
                  12.h.verticalSpace,
                  AppText(
                    AppLocalization.getText(context)
                            ?.phone_verify_gate_subtitle ??
                        "Mijozlarga SMS yuborish va hisobingizni himoyalash uchun telefon raqamingizni tasdiqlang.",
                    fontSize: 13.sp,
                    textAlign: TextAlign.center,
                    color: Theme.of(context).hintColor,
                  ),
                ],
                30.h.verticalSpace,
                CustomTextField(
                  controller: phoneController,
                  enabled: true,
                  keyboardType: TextInputType.phone,
                  title: "${AppLocalization.getText(context)?.phone_number}",
                  labelText:
                      "${AppLocalization.getText(context)?.phone_number}",
                  errorText: errorText,
                  requiredField: true,
                  onChanged: (value) {
                    if (errorText != null) {
                      setState(() {
                        errorText = null;
                      });
                    }
                  },
                ),
                12.h.verticalSpace,
                const Spacer(),
                CustomButtonWidget(
                  title: "${AppLocalization.getText(context)?.continue_}",
                  isLoading: state.isUpdateLoading,
                  onTap: _onContinue,
                ),
                if (widget.isMandatoryGate) ...[
                  8.h.verticalSpace,
                  TextButton(
                    onPressed: () => OnboardingQuizGate.continuePastPhoneGate(),
                    child: AppText(
                      AppLocalization.getText(context)?.later ?? "Keyinroq",
                      fontSize: 14.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
                10.h.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

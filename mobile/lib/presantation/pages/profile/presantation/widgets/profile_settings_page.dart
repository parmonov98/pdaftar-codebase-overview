import 'package:pdaftaruz/service/birthday/birthday_widgets.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:pdaftaruz/constants/app_select_image_type.dart';
import 'package:pdaftaruz/service/page_visit_logger.dart';
import 'package:pdaftaruz/core/imports/imports.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';
import '../riverpod/notifier/profile_notifier.dart';
import 'delete_account_dialog.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  String? _originalPhoneNumber;
  bool? _previousIsVerifiedPhone;
  bool _isAutoSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Log page visit
      PageVisitLogger().logPageVisit('ProfileSettingsPage');
      // Oldingi tanlangan rasmni tozalash
      ref.read(profileProvider.notifier).clearSelectedImage();
      
      // Original telefon raqamini saqlash
      final state = ref.read(profileProvider);
      final notifier = ref.read(profileProvider.notifier);
      final localPhone = LocalStorage.instance.getPhoneNumber();
      final networkPhone = state.userInfoData?.data?.phoneNumber;
      final phone = networkPhone ?? localPhone;
      if (phone.isNotEmpty && phone != 'null') {
        _originalPhoneNumber = phone.replaceAll('+998', '').replaceAll(RegExp(r'[^\d]'), '');
        // Telefon raqamini formatlash (## ### ## ## formatida)
        final cleanPhone = _originalPhoneNumber!;
        if (cleanPhone.length == 9) {
          // Format: 90 123 45 67
          notifier.phoneController.text = 
              '${cleanPhone.substring(0, 2)} ${cleanPhone.substring(2, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7)}';
        } else {
          notifier.phoneController.text = cleanPhone;
        }
      }
      
      // Telefon tasdiqlash holatini saqlash
      _previousIsVerifiedPhone = state.userInfoData?.data?.isVerifiedPhone;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);
    
    // Telefon tasdiqlanganini tekshirish va avtomatik Save qilish
    final currentIsVerifiedPhone = state.userInfoData?.data?.isVerifiedPhone ?? true;
    if (!_isAutoSaving &&
        _previousIsVerifiedPhone != null && 
        _previousIsVerifiedPhone == false && 
        currentIsVerifiedPhone == true) {
      // Telefon tasdiqlangan, avtomatik Save qilish
      _isAutoSaving = true;
      _previousIsVerifiedPhone = currentIsVerifiedPhone;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.update(
          context: context,
          userId: LocalStorage.instance.getID(),
          imagePath: state.selectedImageFile,
          success: () {
            // Rasmni tozalash
            notifier.clearSelectedImage();
            // Profil ma'lumotlarini yangilash
            notifier.getUserInfo();
            // Profil sahifasiga qaytish
            AppNavigator.pop();
          },
        );
      });
    } else if (_previousIsVerifiedPhone != currentIsVerifiedPhone) {
      _previousIsVerifiedPhone = currentIsVerifiedPhone;
    }
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0,0),
        child: AppBar(
          systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            top: 0.00.sh,
            left: 12.0.w,
            right: 12.0.w,
            // bottom: MediaQuery.of(context).viewInsets.bottom
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(1000),
                    onTap: () {
                      AppNavigator.pop();
                    },
                    child:  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: RotatedBox(quarterTurns: 2,
                      child: CustomSvgWidgetAsset(Assets.arrowRightIconSvg,isFlag: false,color: Theme.of(context).textTheme.titleLarge?.color,)),
                    ),
                  ),
                  //const Spacer(flex: 2,),
                  AppText("${AppLocalization.getText(context)?.profile_settings}",
                    fontSize: 16.sp,
                  ),
                  GestureDetector(
                    onTap: (){
                      // "Ha" asks for a one-off 4-digit code first (#538).
                      DeleteAccountDialog.show(
                        context,
                        onConfirmed: () {
                          notifier.deleteUser(userID: state.userInfoData?.data?.id,
                            success: (){
                              AppHelpers.showSnackBarSuccess(message: '${AppLocalization.getText(context)?.delete_account_completed}');
                              AppNavigator.pushAndPopUntil(
                                AuthRoute(),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: CustomSvgWidgetAsset(Assets.trashRedIconSvg, color: context.isDark ? AppColors.redOnDark : AppColors.red,),
                  )
                ],
              ),
              30.h.verticalSpace,
              GestureDetector(
                onTap: (){
                  AppTypeOfImage.selectPickImage(
                      listen: (File data) {
                        // Rasmni state ga saqlash
                        notifier.setSelectedImage(data);
                      },
                      isCamera: false);
                },
                child: Column(
                  children: [
                    Transform.scale(
                      scale: 1.8,
                      child: state.selectedImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.file(
                                state.selectedImageFile!,
                                width: 50.sp,
                                height: 50.sp,
                                fit: BoxFit.cover,
                              ),
                            )
                          : state.userInfoData?.data?.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: FadeInImage(
                                    placeholder: const AssetImage(Assets.accountIconPng),
                                    width: 50.sp,
                                    height: 50.sp,
                                    fit: BoxFit.cover,
                                    image: NetworkImage(state.userInfoData?.data?.image ?? ""),
                                    imageErrorBuilder: (context, data, stacktrace) => Container(
                                      padding: const EdgeInsets.all(8.0),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(
                                        Assets.accountIconPng,
                                        width: 150.w,
                                      ),
                                    ),
                                  ),
                                )
                              : CustomSvgWidgetAsset(
                                  isFlag: true,
                                  Assets.accountIconSvg,
                                  size: 50.sp,
                                  // blendMode: BlendMode.dst,
                                ),
                    ),
                    CustomSvgWidgetAsset(
                      Assets.cameraIconSvg,
                      size: 25.sp,
                      blendMode: BlendMode.dst,
                    )
                  ],
                ),
              ),
              12.h.verticalSpace,
              const BirthdayProfileTile(),
              CustomTextField(
                controller: notifier.nameController,
                textCapitalization: TextCapitalization.words,
                title: "${AppLocalization.getText(context)?.name}",
                labelText: "${AppLocalization.getText(context)?.name}",
              ),
              12.h.verticalSpace,
              // Telefon raqami yo'qligini tekshirish
              _buildPhoneSection(context, notifier, state),
              12.h.verticalSpace,
              // Google Email section
              _buildGoogleEmailSection(context, notifier, state),
              12.h.verticalSpace,
              // Container(
              //   decoration: BoxDecoration(
              //     color: Theme.of(context).cardColor,
              //     borderRadius: BorderRadius.circular(12.r),
              //   ),
              //   child: ListTile(
              //     title: AppText(
              //       "${AppLocalization.getText(context)?.receive_notif}", fontSize: 14.sp, fontWeight: FontWeight.w500,),
              //     trailing: Transform.scale(
              //       scale: 0.7, // Adjust this value to scale the switch
              //       child: Switch.adaptive(
              //         value: state.isNotificationOn,
              //         onChanged: (value) {
              //           notifier.toggleNotification(!state.isNotificationOn);
              //         },
              //         activeColor: Theme.of(context).primaryColor,
              //       ),
              //     ),
              //   ),
              // ),
              const Spacer(),
              CustomButtonWidget(
                title: "${AppLocalization.getText(context)?.save}",
                isLoading: state.isUpdateLoading,
                onTap: () {
                  notifier.update(
                      context: context,
                      userId: LocalStorage.instance.getID(),
                      imagePath: state.selectedImageFile,
                      success: () {
                        // Rasmni tozalash
                        notifier.clearSelectedImage();
                        // Profil ma'lumotlarini yangilash
                        notifier.getUserInfo();
                        // Profil sahifasiga qaytish
                        AppNavigator.pop();
                      });
                },
              ),
              10.h.verticalSpace
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneSection(BuildContext context, ProfileNotifier notifier, ProfileState state) {
    // Telefon raqamini local storage va network javobidan tekshirish
    final localPhone = LocalStorage.instance.getPhoneNumber();
    final networkPhone = state.userInfoData?.data?.phoneNumber;
    final hasPhone = (localPhone.isNotEmpty && localPhone != 'null') || 
                     (networkPhone != null && networkPhone.isNotEmpty && networkPhone != 'null');

    // Joriy telefon raqamini formatlash (faqat raqamlarni olish)
    String getCurrentPhone() {
      if (hasPhone) {
        final phone = networkPhone ?? localPhone;
        // +998 ni olib tashlash va faqat raqamlarni qoldirish
        return phone.replaceAll('+998', '').replaceAll(RegExp(r'[^\d]'), '');
      }
      return '';
    }

    // TextField ichidagi raqamni tekshirish
    final currentText = notifier.phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final originalPhone = _originalPhoneNumber ?? getCurrentPhone();
    final hasChanged = currentText.isNotEmpty && currentText != originalPhone;
    final showVerifyButton = hasChanged && currentText.length >= 9;
    
    // Telefon tasdiqlanmagan bo'lsa va o'zgartirilmagan bo'lsa, tasdiqlash buttonini ko'rsatish
    final isVerifiedPhone = state.userInfoData?.data?.isVerifiedPhone ?? true;
    final showVerifyExistingButton = !isVerifiedPhone && !hasChanged && hasPhone;

    // Telefon raqamini formatlash funksiyasi
    String formatPhoneForSubmission(String phone) {
      String cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
      return '+998$cleanNumber';
    }

    // Telefon raqamini tekshirish
    bool isValidPhoneNumber(String phone) {
      String cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
      final RegExp regex = RegExp(r'^(90|91|93|94|95|97|98|99|50|88|77|33|20)[0-9]{7}$');
      return regex.hasMatch(cleanNumber);
    }

    // Verify button bosilganda (yangi raqam uchun)
    void onVerifyTap() {
      final phone = notifier.phoneController.text.trim();
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
      
      if (cleanPhone.isEmpty) {
        AppHelpers.showSnackBarError(
          errorMessage: AppLocalization.getText(context)?.this_field_is_mandatory ?? 
                       "Telefon raqami kiritilishi shart",
        );
        return;
      }
      
      if (!isValidPhoneNumber(cleanPhone)) {
        AppHelpers.showSnackBarError(
          errorMessage: AppLocalization.getText(context)?.sorry_an_unknown_error_occurred_please_try_again_later ?? 
                       "Iltimos, to'g'ri telefon raqamini kiriting",
        );
        return;
      }

      final formattedPhone = formatPhoneForSubmission(cleanPhone);
      final userId = LocalStorage.instance.getID();

      notifier.updatePhoneNumber(
        context: context,
        userId: userId,
        phoneNumber: formattedPhone,
        success: () {
          // Navigate to OTP page for verification
          AppNavigator.push(
            OtpRoute(
              phoneNumber: cleanPhone,
              isForgotPassword: false,
              isPhoneVerification: true,
            ),
          );
        },
      );
    }

    // Mavjud telefon raqamini tasdiqlash uchun
    void onVerifyExistingPhoneTap() {
      final phone = networkPhone ?? localPhone;
      if (phone.isEmpty || phone == 'null') {
        AppHelpers.showSnackBarError(
          errorMessage: AppLocalization.getText(context)?.sorry_an_unknown_error_occurred_please_try_again_later ?? 
                       "Telefon raqami topilmadi",
        );
        return;
      }

      final cleanPhone = phone.replaceAll('+998', '').replaceAll(RegExp(r'[^\d]'), '');
      final userId = LocalStorage.instance.getID();

      // Mavjud telefon raqamiga SMS jo'natish
      notifier.updatePhoneNumber(
        context: context,
        userId: userId,
        phoneNumber: phone, // To'liq formatda (+998...)
        success: () {
          // Navigate to OTP page for verification
          AppNavigator.push(
            OtpRoute(
              phoneNumber: cleanPhone,
              isForgotPassword: false,
              isPhoneVerification: true,
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextField(
                controller: notifier.phoneController,
                enabled: true,
                keyboardType: TextInputType.phone,
                title: "${AppLocalization.getText(context)?.phone_number}",
                labelText: "${AppLocalization.getText(context)?.phone_number}",
                inputFormatters: [
                  MaskedInputFormatter('## ### ## ##'),
                ],
                onChanged: (value) {
                  // TextField o'zgarganda state'ni yangilash
                  setState(() {});
                },
              ),
            ),
            if (showVerifyButton) ...[
              8.horizontalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: state.isUpdateLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : GestureDetector(
                        onTap: onVerifyTap,
                        child: Text(
                          AppLocalization.getText(context)?.verify ?? 'Verify',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ] else if (showVerifyExistingButton) ...[
              8.horizontalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: state.isUpdateLoading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: const CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : GestureDetector(
                        onTap: onVerifyExistingPhoneTap,
                        child: Text(
                          AppLocalization.getText(context)?.verify ?? 'Tasdiqlash',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleEmailSection(BuildContext context, ProfileNotifier notifier, ProfileState state) {
    final googleEmail = state.userInfoData?.data?.googleEmail ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (googleEmail.isNotEmpty) ...[
          // Google email ko'rsatiladi
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email,
                  size: 20.sp,
                  color: context.palette.accent,
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        "Google Email",
                        fontSize: 12.sp,
                        color: context.isDark ? context.palette.textSecondary : AppColors.greyColor3,
                        fontWeight: FontWeight.w500,
                      ),
                      4.verticalSpace,
                      AppText(
                        googleEmail,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  size: 20.sp,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
        ] else ...[
          // Google account ulanmagan bo'lsa, ulash tugmasi
          GestureDetector(
            onTap: () async {
              await notifier.linkGoogleAccount(
                success: () {
                  // User info will be refreshed automatically
                  AppHelpers.showSnackBarSuccess(
                    message: "Google Account muvaffaqiyatli ulandi",
                  );
                },
                failure: (errorMessage) {
                  // Error is already shown in the method
                },
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.palette.accent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20.sp,
                    color: context.palette.accent,
                  ),
                  8.horizontalSpace,
                  AppText(
                    "Google Account'ni ulash",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.palette.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

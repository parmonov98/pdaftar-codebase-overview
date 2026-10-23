import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import '../../../../../constants/app_text_field_errors_status.dart';

@RoutePage()
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(
            top: 0.00.sh,
            left: 12.0.w,
            right: 12.0.w,
            // bottom: MediaQuery.of(context).viewInsets.bottom
          ),
          // Every role changes their own password the same way: old + new
          // password to users/{id}/change_password (Trello #547). Sellers
          // used to post to seller/{id}/change-password, which is the
          // owner's route for a seller and always refused them.
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
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
                            color:
                                Theme.of(context).textTheme.titleLarge?.color,
                          )),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(),
                  ),
                  // Shrinks instead of overflowing at large text sizes.
                  Flexible(
                    flex: 6,
                    child: AppText(
                      "${AppLocalization.getText(context)?.change_password}",
                      fontSize: 16.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(),
                  )
                ],
              ),
              12.h.verticalSpace,
              CustomTextField(
                controller: notifier.passwordController,
                labelText:
                    "${AppLocalization.getText(context)?.entering_new_password}",
                title: "${AppLocalization.getText(context)?.new_password}",
                errorText: AppTextFieldErrorsStatus.status(
                    state.errorMessage, "new password"),
              ),
              0.02.sh.verticalSpace,
              CustomTextField(
                title:
                    "${AppLocalization.getText(context)?.new_password_confirmation}",
                controller: notifier.passwordConfirmationController,
                labelText:
                    "${AppLocalization.getText(context)?.new_password_confirmation}",
                errorText: AppTextFieldErrorsStatus.status(
                    state.errorMessage, "confirmation password"),
              ),
              0.02.sh.verticalSpace,
              CustomTextField(
                requiredField: true,
                title: "${AppLocalization.getText(context)?.old_password}",
                controller: notifier.oldPasswordController,
                labelText: "${AppLocalization.getText(context)?.old_password}",
                errorText: AppTextFieldErrorsStatus.status(
                    state.errorMessage, "old password"),
              ),
              const Spacer(),
              CustomButtonWidget(
                title: "${AppLocalization.getText(context)?.save}",
                isLoading: state.isUpdateLoading,
                onTap: () {
                  state.isUpdateLoading
                      ? null
                      : notifier.changePasswordOwner(
                          context: context,
                          success: () {
                            try {
                              MixpanelAnalyticsService.instance
                                  .track(MixpanelEvents.passwordChanged);
                            } catch (_) {}
                            AppNavigator.pop();
                            notifier.getUserInfo();
                          },
                          unAuthorised: () {
                            AppNavigator.pop();
                          },
                          userId: LocalStorage.instance.getID());
                },
              ),
              10.h.verticalSpace
            ],
          ),
        ),
      ),
    );
  }
}

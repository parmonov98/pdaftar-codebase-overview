import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';
import 'package:pdaftaruz/presantation/themes/riverpod/provider/theme_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdaftaruz/presantation/themes/riverpod/state/theme_state.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class ChangeThemeModal extends ConsumerStatefulWidget {
  const ChangeThemeModal({super.key});

  @override
  ConsumerState<ChangeThemeModal> createState() => _ChangeThemeModalState();
}

class _ChangeThemeModalState extends ConsumerState<ChangeThemeModal> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((re) {
      final themeNotifier = ref.read(themeProvider(0).notifier);
      themeNotifier.getTheme(LocalStorage.instance.getThemeMode(), context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeProvider(0));
    final notifier = ref.watch(themeProvider(0).notifier);
    return Container(
      padding: EdgeInsets.only(
        top: 0.h,
        left: 24.0.w,
        right: 24.0.w,
      ),
      // One group for the whole set: each radio used to fall back to its own
      // value, so with no theme stored yet all three rendered selected.
      child: RadioGroup<ThemeModes>(
        // Without it no option ever showed as selected (#628).
        groupValue: state.theme,
        onChanged: (value) {
          if (value != null) notifier.changeTheme(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AppText(
                "${AppLocalization.getText(context)?.themes}",
                fontSize: 16.sp,
              ),
            ),
            12.h.verticalSpace,
            GestureDetector(
              onTap: () {
                notifier.changeTheme(ThemeModes.light);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    ListTile(
                        minTileHeight: 55.h,
                        title: Row(
                          children: [
                            CustomSvgWidgetAsset(
                              Assets.sunIconSvg,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            12.horizontalSpace,
                            AppText(
                              "${AppLocalization.getText(context)?.light_theme}",
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ],
                        ),
                        trailing: CupertinoRadio(
                          inactiveColor: _radioOff(context),
                          activeColor: AppColors.primaryColor,
                          value: ThemeModes.light,
                        )),
                  ],
                ),
              ),
            ),
            12.h.verticalSpace,
            GestureDetector(
              onTap: () {
                notifier.changeTheme(ThemeModes.dark);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                    minTileHeight: 55.h,
                    title: Row(
                      children: [
                        CustomSvgWidgetAsset(
                          Assets.moonIconSvg,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        12.horizontalSpace,
                        AppText(
                          "${AppLocalization.getText(context)?.dark_theme}",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ],
                    ),
                    trailing: CupertinoRadio(
                      activeColor: AppColors.primaryColor,
                      inactiveColor: _radioOff(context),
                      value: ThemeModes.dark,
                      useCheckmarkStyle: false,
                    )),
              ),
            ),
            12.h.verticalSpace,
            GestureDetector(
              onTap: () {
                notifier.changeTheme(ThemeModes.system);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                    minTileHeight: 55.h,
                    title: Row(
                      children: [
                        CustomSvgWidgetAsset(
                          Assets.themeIconSvg,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        12.horizontalSpace,
                        AppText(
                          "${AppLocalization.getText(context)?.systemic_theme}",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ],
                    ),
                    trailing: CupertinoRadio(
                      activeColor: AppColors.primaryColor,
                      inactiveColor: _radioOff(context),
                      value: ThemeModes.system,
                      useCheckmarkStyle: false,
                    )),
              ),
            ),
            12.h.verticalSpace,
            CustomButtonWidget(
              onTap: () {
                try {
                  MixpanelAnalyticsService.instance.track(
                      MixpanelEvents.themeChanged,
                      {'theme': (state.theme ?? ThemeModes.light).name});
                } catch (_) {}
                notifier.setTheme(state.theme ?? ThemeModes.light, context);
                AppNavigator.pop();
              },
              title: "${AppLocalization.getText(context)?.save}",
              isLoading: false,
            ),
            22.h.verticalSpace,
          ],
        ),
      ),
    );
  }
}

/// Unselected radio fill. The tile's own colour made it invisible (#628).
Color _radioOff(BuildContext context) => context.isDark
    ? AppColors.borderDarkColor
    : AppColors.textFieldBorderColorLight;

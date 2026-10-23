import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import 'package:pdaftaruz/service/localization/riverpod/provider/localization_provider.dart';
import 'package:pdaftaruz/service/localization/riverpod/notifier/localization_notifier.dart';
import 'package:flutter/cupertino.dart';

class ChangeLangModal extends ConsumerStatefulWidget {
  const ChangeLangModal({super.key});

  @override
  ConsumerState<ChangeLangModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends ConsumerState<ChangeLangModal> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((re) {
      final langNotifier = ref.read(langProvider(0).notifier);
      langNotifier.getLang(LocalStorage.instance.getLang(), context);
    });
  }

  static const _languageCodes = [
    'uz',
    'ru',
    'en',
    'kaa',
    'kk',
    'ky',
    'tg',
    'tr',
    'ar',
  ];

  String _languageName(BuildContext context, String code) {
    final l10n = AppLocalization.getText(context);
    return switch (code) {
      'ru' => l10n?.language_name_ru ?? 'Русский язык',
      'en' => l10n?.language_name_en ?? 'English',
      'kaa' => l10n?.language_name_kaa ?? 'Qaraqalpaq tili',
      'kk' => l10n?.language_name_kk ?? 'Қазақ тілі',
      'ky' => l10n?.language_name_ky ?? 'Кыргыз тили',
      'tg' => l10n?.language_name_tg ?? 'Тоҷикӣ',
      'tr' => l10n?.language_name_tr ?? 'Türkçe',
      'ar' => l10n?.language_name_ar ?? 'العربية',
      _ => l10n?.language_name_uz ?? "O'zbek tili",
    };
  }

  Widget _flag(String code) {
    final svg = switch (code) {
      'uz' => Assets.uzbIconSvg,
      'ru' => Assets.rusIconSvg,
      'kaa' => Assets.kaaIconSvg,
      _ => null,
    };
    if (svg != null) {
      return CustomSvgWidgetAsset(svg, size: 0.035.sh, isFlag: true);
    }
    final emoji = switch (code) {
      'en' => '🇬🇧',
      'kk' => '🇰🇿',
      'ky' => '🇰🇬',
      'tg' => '🇹🇯',
      'ar' => '🇸🇦',
      _ => '🇹🇷',
    };
    return SizedBox(
      width: 0.035.sh,
      height: 0.035.sh,
      child: Center(child: Text(emoji, style: TextStyle(fontSize: 0.025.sh))),
    );
  }

  Widget _languageTile(
      BuildContext context, String code, AppLocalizationNotifier langNotifier) {
    return GestureDetector(
      key: ValueKey('profile_language_$code'),
      onTap: () => langNotifier.changeLang(code),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ListTile(
          minTileHeight: 55.h,
          leading: _flag(code),
          title: AppText(
            _languageName(context, code),
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
          trailing: CupertinoRadio(
            inactiveColor: Theme.of(context).canvasColor,
            activeColor: AppColors.primaryColor,
            value: code,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langNotifier = ref.read(langProvider(0).notifier);
    final state = ref.watch(langProvider(0));

    return Container(
      padding: EdgeInsets.only(
        top: 0.h,
        left: 24.0.w,
        right: 24.0.w,
      ),
      // One group for the whole set: each radio previously carried its own
      // groupValue, and one of them fell back to 'ru' while the rest fell back
      // to 'uz' — so with no language stored yet, two of them rendered
      // selected at once.
      child: RadioGroup<String>(
        groupValue: state.localLang ?? 'uz',
        onChanged: (value) {
          if (value != null) langNotifier.changeLang(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AppText(
                "${AppLocalization.getText(context)?.lang}",
                fontSize: 16.sp,
              ),
            ),
            12.h.verticalSpace,
            // Every language the app ships, in the order the first-launch
            // picker shows them. Kazakh, Kyrgyz, Tajik and Turkish were only
            // offered there, so a signed-in user had no way to switch to them.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final code in _languageCodes) ...[
                      _languageTile(context, code, langNotifier),
                      if (code != _languageCodes.last) 10.h.verticalSpace,
                    ],
                  ],
                ),
              ),
            ),
            12.h.verticalSpace,
            CustomButtonWidget(
              onTap: () async {
                try {
                  MixpanelAnalyticsService.instance.track(
                      MixpanelEvents.languageChanged,
                      {'language': state.localLang ?? 'uz'});
                } catch (_) {}
                // Pop the modal BEFORE the restart. RestartWidget remounts the
                // entire subtree, but appRouter.navigatorKey is a GlobalKey, so
                // Flutter preserves the Navigator's state (route stack + open
                // modals) across the rebuild. Without this pop, the modal route
                // survives the restart and the picker stays open while the rest
                // of the UI is in the new language. Pop first → modal route is
                // removed from the stack → restart rebuilds with a navigator
                // that no longer has it.
                AppNavigator.pop();
                await langNotifier.setLang(state.localLang ?? "uz", context);
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

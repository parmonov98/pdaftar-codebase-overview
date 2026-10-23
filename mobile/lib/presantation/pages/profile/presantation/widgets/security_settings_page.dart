import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/global_widgets/custom_switch.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_analytics_service.dart';
import 'package:pdaftaruz/service/mixpanel/mixpanel_events.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';

@RoutePage()
class SecuritySettingsPage extends ConsumerStatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SecuritySettingsPageState();

}
class _SecuritySettingsPageState extends ConsumerState<ConsumerStatefulWidget>{
  @override
  void initState() {
    super.initState();
    try { MixpanelAnalyticsService.instance.track(MixpanelEvents.securitySettingsViewed, {}); } catch (_) {}
    // ProfileState defaults isPinCodeEnabled to true; show what is stored.
    Future.microtask(
        () => ref.read(profileProvider.notifier).refreshPinCodeEnabled());
  }

  @override
  Widget build(BuildContext context ) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);
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
                        child:  Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: context.palette.icon,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(),
                    ),
                    AppText(
                      "${AppLocalization.getText(context)?.security_settings}",
                      fontSize: 16.sp,
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(),
                    )
                  ],
                ),
                16.h.verticalSpace,
                CustomSwitch(label: "Pin Code", value: state.isPinCodeEnabled, onChanged: (value){
                  notifier.switchPINCode(value: value);
                }),
                16.h.verticalSpace,
                state.isPinCodeEnabled? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      await notifier.openSetPinCodePage();
                      await notifier.refreshPinCodeEnabled();
                    },
                    child: ListTile(
                      title: AppText(
                        "${AppLocalization.getText(context)?.change_pin_code}",
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      trailing: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
                ) : const SizedBox.shrink(),
              ],
            ),
          )),
    );
  }

}

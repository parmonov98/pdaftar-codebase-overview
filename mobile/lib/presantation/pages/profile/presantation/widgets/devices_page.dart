import 'package:pdaftaruz/presantation/themes/app_palette.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/devices_widget.dart';

import '../../../../../constants/theme/app_status_bar_theme.dart';

@RoutePage()
class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(profileProvider.notifier);
      notifier.getSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(0, 0),
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
                      child: Icon(
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
                    "Qurilmalar",
                    fontSize: 16.sp,
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(),
                  )
                ],
              ),
              16.h.verticalSpace,
              const Expanded(
                child: SingleChildScrollView(
                  child: DevicesWidget(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

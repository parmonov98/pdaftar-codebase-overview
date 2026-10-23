import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:badges/badges.dart' as badges;

import '../../../../../constants/theme/app_status_bar_theme.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

@RoutePage()
class SubscriptionsPage extends ConsumerStatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  ConsumerState<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage> with TickerProviderStateMixin{

  late TabController _tabController;

  @override
  void didChangeDependencies() {
    ref.read(profileProvider.notifier);
    _tabController = TabController(
      length: ref.read(profileProvider.notifier).buildTabs(context).length,
      vsync: this,
    );
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    final state = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: AppStatusBarThemes.changeDefaultThemeStatusBar(),

        title: AppText("${AppLocalization.getText(context)?.subscriptions}"),
      ),
      body: Column(
        children: [
          10.h.verticalSpace,
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                  notifier.buildTabs(context).length,
                      (index) => Expanded(
                    child:  badges.Badge(
                      // stackFit: StackFit.passthrough,
                      badgeStyle: badges.BadgeStyle(
                        padding: EdgeInsets.zero,
                        borderRadius:
                        BorderRadius.circular(45),
                        badgeColor: context.palette.surface,
                        shape: badges.BadgeShape.square,
                        // padding: EdgeInsets.all(5),
                        borderSide: BorderSide(
                            color: state.nextPage == index
                                ? context.palette.accent
                                : Theme.of(context).disabledColor,
                            width: 1),
                      ),
                      showBadge:
                      notifier.tabsBadges()[index] !=
                          0,

                      // offset: Offset(0.sp,0.1),
                      position: badges.BadgePosition.topEnd(
                        end: 12,
                        top: -4,
                      ),

                      badgeContent: Padding(
                        padding:
                        const EdgeInsets.only(
                            left:3,right: 3,top: 2),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0,horizontal: 5),
                            child: AppText(
                              "${notifier.tabsBadges()[index]}",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              textAlign: TextAlign.end,
                              color: state.nextPage == index
                                  ? context.palette.accent
                                  : context.palette.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        height: 42.sp,
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border: Border.all(
                              color: state.nextPage == index
                                  ? context.palette.accent
                                  : Theme.of(context).disabledColor,
                            ),
                            borderRadius: BorderRadius.circular(8)),
                        child: InkWell(
                          onTap: () {
                            notifier.changeTab(index: index);
                            _tabController.animateTo(index,
                                duration: const Duration(
                                    milliseconds: 450));
                          },
                          child:
                          Center(
                            child: AppText(
                                notifier
                                    .buildTabs(context)[index],
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: state.nextPage == index
                                    ? Theme.of(context)
                                    .textTheme.titleLarge?.color
                                    : context.palette.textSecondary),
                          ),


                        ),
                      ),
                    ),
                  )),
            ),
          )
        ],
      ),
    );
  }
}

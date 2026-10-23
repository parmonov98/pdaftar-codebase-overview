import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/riverpod/provider/home_provider.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/profile_page_menu.dart';

import '../../../../constants/theme/app_status_bar_theme.dart';

@RoutePage()
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle(AppStatusBarThemes.changeDefaultThemeStatusBar);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final notifier = ref.read(profileProvider.notifier);
      notifier.phoneController.text =
          LocalStorage.instance.getPhoneNumber().format.replaceAll("+998 ", "");
      //notifier.getUserInfo();
      notifier.nameController.text = LocalStorage.instance.getUserName();
      // notifier.emailController.text = LocalStorage.instance.getEmail();

      // Load payment providers early to avoid delay on + tap
      notifier.loadPaymentProviders();
      // Resolve the seller's owner so the Profil header swaps the
      // seller's own identity for the owner's name/phone/avatar.
      // No-op (404) for owners — getSellerOwner swallows that case.
      notifier.getSellerOwner();
    });
  }

  final PageStorageBucket _bucket = PageStorageBucket();
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(profileProvider.notifier);
    // No field of ProfileState is read in this build — the menu child
    // watches what it needs itself. A bare watch here rebuilt the whole
    // Scaffold on every one of the notifier's loading
    // flag flips during the first-open API burst.

    return PageStorage(
      bucket: _bucket,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size(0, 0),
          child: AppBar(
            systemOverlayStyle:
                AppStatusBarThemes.changeDefaultThemeStatusBar(),
          ),
        ),
        resizeToAvoidBottomInset: false,
        // The menu runs under the floating glass nav and ends with its
        // inset (SliverNavBarInset).
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator.adaptive(
            onRefresh: () {
              ref.read(homeProvider(0).notifier).getSellerPermissions();
              ref.read(homeProvider(0).notifier).checkOwnerTariffs();
              return notifier.refreshAccount();
            },
            child: const ProfilePageMenu(),
          ),
        ),
        // No floatingActionButton: Baholash / Ulashish are a row inside the
        // list (ProfileAppActionsRow); floating, they covered
        // "Foydalanuvchilar" (#591). AI yordamchi is the app-wide bubble in
        // app.dart (#619).
      ),
    );
  }
}

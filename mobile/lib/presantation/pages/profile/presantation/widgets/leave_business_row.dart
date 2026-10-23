import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/core/shop/business_restart.dart';
import 'package:pdaftaruz/core/shop/shop_membership_guard.dart';
import 'package:pdaftaruz/presantation/pages/home/presantation/widgets/business_switcher_logic.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_row.dart';

/// "Biznesdan chiqish" (#543, owner decision Q8): a seller leaves the
/// business that is open now. Shown only while that business is someone
/// else's and the user has another business to fall back to — the last
/// one can't be left this way.
class LeaveBusinessRow extends ConsumerWidget {
  const LeaveBusinessRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ShopMembershipGuard.cachedShops() ?? const [];
    final currentId = LocalStorage.instance.getSelectedShopId();
    final current = shops.where((s) => s.id == currentId).firstOrNull;
    if (current == null || !current.isSellerRow || shops.length < 2) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalization.getText(context);
    return SettingsRow(
      title: l10n?.leave_business ?? 'Biznesdan chiqish',
      iconAsset: Assets.logOutIconSvg,
      destructive: true,
      onTap: () => AppHelpers.appAlertDialog(
        context: context,
        title: l10n?.leave_business ?? 'Biznesdan chiqish',
        content: l10n?.leave_business_confirm(current.name ?? '') ?? '',
        // Short label: "Biznesdan chiqish" wrapped and clipped in the
        // dialog's half-width button (seen on the emulator).
        actionTitle: l10n?.yes ?? 'Ha',
        onTap: () async {
          // Strings first: the dialog's context is gone after pop.
          final left = l10n?.business_left(current.name ?? '') ?? '';
          AppNavigator.pop();
          final error = await ref
              .read(profileProvider.notifier)
              .leaveBusiness(current.id!);
          if (error != null) {
            AppHelpers.showSnackBarError(errorMessage: error);
            return;
          }
          final remaining = shops.where((s) => s.id != current.id).toList();
          final next = BusinessSwitcherLogic.validSelection(
            remaining,
            null,
            ownBusinessLimit: LocalStorage.instance.getOwnBusinessLimit() ?? 1,
          );
          if (next?.id != null) {
            await LocalStorage.instance.setSelectedShopId(next!.id!);
            if (next.userType != null) {
              await LocalStorage.instance.setUserType(next.userType);
            }
          }
          AppHelpers.showSnackBarSuccess(message: left);
          restartIntoBusiness();
        },
      ),
    );
  }
}

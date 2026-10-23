import 'package:flutter/cupertino.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/riverpod/provider/font_scale_provider.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

/// Bottom sheet that lets the user pick a global text-size preset.
///
/// Live-previews each preset (the preview line uses [MediaQuery.textScalerOf]
/// implicitly because we apply the scale at the root in `app.dart`). The
/// selection is committed immediately on tap and persisted via [LocalStorage].
class FontSizeModal extends ConsumerStatefulWidget {
  const FontSizeModal({super.key});

  @override
  ConsumerState<FontSizeModal> createState() => _FontSizeModalState();
}

class _FontSizeModalState extends ConsumerState<FontSizeModal> {
  String _label(BuildContext context, FontScalePreset preset) {
    final t = AppLocalization.getText(context);
    switch (preset) {
      case FontScalePreset.small:
        return t?.font_size_small ?? 'Kichik';
      case FontScalePreset.regular:
        return t?.font_size_default ?? 'Standart';
      case FontScalePreset.large:
        return t?.font_size_large ?? 'Katta';
      case FontScalePreset.extraLarge:
        return t?.font_size_extra_large ?? 'Juda katta';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so the modal rebuilds the moment the user picks a
    // preset — gives the live preview area below an immediate scale update
    // (in addition to the underlying global MediaQuery refresh applied at
    // the app root).
    final currentScale = ref.watch(fontScaleProvider);
    final selected = FontScalePreset.fromScale(currentScale);
    final previewText =
        AppLocalization.getText(context)?.font_size_preview ?? 'Matn ko\'rinishi';
    return Container(
      padding: EdgeInsets.only(top: 0.h, left: 24.w, right: 24.w, bottom: 22.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AppText(
              "${AppLocalization.getText(context)?.font_size}",
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          12.h.verticalSpace,

          // Live preview banner — scales with the currently-selected preset.
          // We override MediaQuery locally (rather than relying on the
          // global wrapper) so the preview reflects the choice instantly,
          // even before the rest of the app has repainted.
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(currentScale),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewText,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  6.h.verticalSpace,
                  Text(
                    _label(context, selected),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).hintColor,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ],
              ),
            ),
          ),
          14.h.verticalSpace,

          for (final preset in FontScalePreset.values) ...[
            _PresetTile(
              label: _label(context, preset),
              previewText: previewText,
              scale: preset.scale,
              isSelected: selected == preset,
              onTap: () {
                ref.read(fontScaleProvider.notifier).setScale(preset.scale);
              },
            ),
            10.h.verticalSpace,
          ],
          12.h.verticalSpace,
          CustomButtonWidget(
            onTap: () => AppNavigator.pop(),
            title: "${AppLocalization.getText(context)?.save}",
            isLoading: false,
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.label,
    required this.previewText,
    required this.scale,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String previewText;
  final double scale;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: ListTile(
          minTileHeight: 60.h,
          title: AppText(
            label,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          subtitle: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: AppText(
              previewText,
              fontSize: 14.sp,
              color: Theme.of(context).hintColor,
            ),
          ),
          trailing: RadioGroup<double>(
            groupValue: isSelected ? scale : -1,
            onChanged: (_) => onTap(),
            child: CupertinoRadio<double>(
              // The tile's own colour made it invisible (#628).
              inactiveColor: context.isDark
                  ? AppColors.borderDarkColor
                  : AppColors.textFieldBorderColorLight,
              activeColor: AppColors.primaryColor,
              value: scale,
            ),
          ),
        ),
      ),
    );
  }
}

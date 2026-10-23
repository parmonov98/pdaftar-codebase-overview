import 'package:pdaftaruz/core/feedback/game_feel_settings.dart';
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_row.dart';

/// "Ovoz effektlari" and "Tebranish" in Profil → Sozlamalar (Gamification
/// Phase 1, Trello #711).
///
/// Only for shops in the game-feel A/B treatment group: elsewhere there is
/// nothing to switch, and an extra pair of switches would only confuse.
class GameFeelSettingsRows extends StatelessWidget {
  const GameFeelSettingsRows({super.key});

  static const soundIconSvg = 'assets/icons/svg/sound_effects.svg';
  static const vibrationIconSvg = 'assets/icons/svg/vibration.svg';

  @override
  Widget build(BuildContext context) {
    final settings = GameFeelSettings.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: GameFeelVariant.instance.enabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();
        final l10n = AppLocalization.getText(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: settings.sound,
              builder: (context, on, _) => SettingsRow(
                title: l10n?.game_feel_sound ?? 'Ovoz effektlari',
                subtitle:
                    l10n?.game_feel_sound_subtitle ?? 'Saqlashda past ovoz',
                iconAsset: soundIconSvg,
                onTap: () => settings.setSound(!on),
                trailing: Switch.adaptive(
                  value: on,
                  activeThumbColor: AppColors.primaryColor,
                  onChanged: settings.setSound,
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: settings.vibration,
              builder: (context, on, _) => SettingsRow(
                title: l10n?.game_feel_vibration ?? 'Tebranish',
                iconAsset: vibrationIconSvg,
                onTap: () => settings.setVibration(!on),
                trailing: Switch.adaptive(
                  value: on,
                  activeThumbColor: AppColors.primaryColor,
                  onChanged: settings.setVibration,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

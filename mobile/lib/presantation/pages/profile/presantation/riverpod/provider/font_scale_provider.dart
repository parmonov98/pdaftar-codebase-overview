import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdaftaruz/core/storage/get_storage/local_storage.dart';

/// Notifier holding the user-selected text size multiplier.
///
/// Hydrated from [LocalStorage.getFontScale] at construction and persisted on
/// every change. Wrapped at app root via `MediaQuery(textScaler: ...)`.
class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(LocalStorage.instance.getFontScale());

  /// Available presets — keep in sync with [FontScalePreset].
  static const double small = 0.85;
  static const double regular = 1.0;
  static const double large = 1.15;
  static const double extraLarge = 1.30;

  Future<void> setScale(double value) async {
    if (state == value) return;
    state = value;
    await LocalStorage.instance.setFontScale(value);
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier();
});

/// Discrete font-size presets exposed in the UI.
enum FontScalePreset {
  small(FontScaleNotifier.small),
  regular(FontScaleNotifier.regular),
  large(FontScaleNotifier.large),
  extraLarge(FontScaleNotifier.extraLarge);

  const FontScalePreset(this.scale);

  final double scale;

  static FontScalePreset fromScale(double scale) {
    // Pick the closest preset to whatever's stored, so a stale or migrated
    // value still maps to a selectable radio item.
    FontScalePreset closest = FontScalePreset.regular;
    double bestDelta = double.infinity;
    for (final preset in FontScalePreset.values) {
      final delta = (preset.scale - scale).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        closest = preset;
      }
    }
    return closest;
  }
}

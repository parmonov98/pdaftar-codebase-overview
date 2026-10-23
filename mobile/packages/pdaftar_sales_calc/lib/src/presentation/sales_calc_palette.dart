import 'package:flutter/material.dart';

/// Dark-mode colours for the sales calculator (Trello #649).
///
/// The package can't import the app, so the app's dark tokens are mirrored
/// here. Each call site passes its original light colour, which is returned
/// unchanged when the theme is light — light mode stays pixel-identical.
class SalesCalcPalette {
  const SalesCalcPalette._(this.isDark);

  factory SalesCalcPalette.of(BuildContext context) =>
      SalesCalcPalette._(Theme.of(context).brightness == Brightness.dark);

  final bool isDark;

  // App dark tokens (AppColors in the host app).
  static const _page = Color(0xFF15202B); // darkColor
  static const _surface = Color(0xFF202932); // cardDarkColor
  static const _raised = Color(0xFF29323C); // selectedTabDarkColor
  static const _border = Color(0xFF343B43); // borderDarkColor
  static const _handle = Color(0xFF4F4F4F); // greyColor2, sheet handle
  static const _textSecondary = Color(0xFF98A2B3); // textFieldLabelColor
  static const _disabled = Color(0xFF667085); // disabledColorText
  static const _accent = Color(0xFFB692F6); // primaryColorOnDark
  // #7C3AED at 18% over cardDarkColor: a purple tint white text reads on.
  static const _accentTint = Color(0xFF312C54);
  // #059669 is 4.1:1 on the dark page; the lighter brand green is 6.3:1.
  static const _success = Color(0xFF10B981);

  Color pick(Color light, Color dark) => isDark ? dark : light;

  /// Page / row background.
  Color page(Color light) => pick(light, _page);

  /// Bars, sheets and dropdowns that sit above the page.
  Color surface(Color light) => pick(light, _surface);

  /// Chips, keys and icon buttons.
  Color raised(Color light) => pick(light, _raised);

  Color border(Color light) => pick(light, _border);
  Color handle(Color light) => pick(light, _handle);
  Color text(Color light) => pick(light, Colors.white);
  Color textSecondary(Color light) => pick(light, _textSecondary);
  Color disabled(Color light) => pick(light, _disabled);

  /// Brand purple used as text, icon or outline. Fills keep the purple.
  Color accent(Color light) => pick(light, _accent);

  /// Light purple tint behind a selected / active element.
  Color accentTint(Color light) => pick(light, _accentTint);

  Color success(Color light) => pick(light, _success);
}

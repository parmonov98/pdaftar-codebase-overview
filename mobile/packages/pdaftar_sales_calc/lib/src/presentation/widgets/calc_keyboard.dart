import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../sales_calc_palette.dart';

/// Key metrics, scaled up from the original 44/18/20/4 because the keys
/// were fiddly to hit one-handed at a till. Raw numbers here; `.sp` is
/// applied at each use site so ScreenUtil is only read during build.
/// File-scoped so _KeyButton can share them with CalcKeyboard.
const double _keyHeight = 56;
const double _keyFontSize = 22;
const double _keyIconSize = 24;
const double _rowGap = 6;

/// Custom calculator keyboard with numbers and operators.
class CalcKeyboard extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const CalcKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onSubmit,
    required this.onClear,
  });

  static const _accentColor = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final p = SalesCalcPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.page(const Color(0xFFF5F5F5)),
        border: Border(top: BorderSide(color: p.border(Colors.grey.shade300))),
      ),
      padding: EdgeInsets.only(
        left: 4.sp,
        right: 4.sp,
        top: 6.sp,
        bottom: MediaQuery.of(context).padding.bottom + 6.sp,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: 7 8 9 * backspace
          //   Display '*' to match the syntax users actually type in
          //   the Ifoda column (e.g. `20*2400`). The evaluator parses
          //   '*' directly — no display/emit divergence needed.
          _buildRow([
            _numKey('7'),
            _numKey('8'),
            _numKey('9'),
            _opKey(p, '*'),
            _actionKey(p, Icons.backspace_outlined, onBackspace),
          ]),
          SizedBox(height: _rowGap.sp),
          // Row 2: 4 5 6 + -
          //   + and - are inert (Trello #153): a row is one product and
          //   one operation — narx*soni. They stay visible so the grid
          //   keeps its shape, but greyed out and emitting nothing.
          _buildRow([
            _numKey('4'),
            _numKey('5'),
            _numKey('6'),
            _opKey(p, '+', enabled: false),
            _opKey(p, '-', enabled: false),
          ]),
          SizedBox(height: _rowGap.sp),
          // Row 3: 1 2 3 ÷ done — ÷ inert for the same reason as + and -.
          _buildRow([
            _numKey('1'),
            _numKey('2'),
            _numKey('3'),
            _opKey(p, '÷', emit: '/', enabled: false),
            _actionKey(p, Icons.keyboard_return, onSubmit, color: _accentColor),
          ]),
          SizedBox(height: _rowGap.sp),
          // Row 4: C 0 00 . done
          _buildRow([
            _specialKey('C', onClear),
            _numKey('0'),
            _numKey('00'),
            _numKey('.'),
            _numKey(' '),
          ]),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> keys) {
    return Row(
      children: keys.map((k) => Expanded(child: k)).toList(),
    );
  }

  Widget _numKey(String value) {
    return _KeyButton(
      label: value == ' ' ? '' : value,
      onTap: () => onKeyPressed(value),
    );
  }

  /// `op` is what the user sees on the key; `emit` is what travels
  /// into the controller. Defaults to the same value when unspecified.
  /// `enabled: false` renders the key greyed out and inert — used for
  /// the operators a row is not allowed to contain (see Trello #153).
  Widget _opKey(SalesCalcPalette p, String op,
      {String? emit, bool enabled = true}) {
    final emitted = emit ?? op;
    return _KeyButton(
      label: op,
      onTap: enabled ? () => onKeyPressed(emitted) : () {},
      textColor: enabled
          ? p.accent(_accentColor)
          : p.disabled(Colors.grey.shade400),
      fontWeight: FontWeight.w700,
    );
  }

  Widget _specialKey(String label, VoidCallback onTap) {
    return _KeyButton(
      label: label,
      onTap: onTap,
      textColor: Colors.red.shade400,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _actionKey(SalesCalcPalette p, IconData icon, VoidCallback onTap,
      {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.sp),
      child: Material(
        color: color ?? p.border(Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onTap,
          child: Container(
            height: _keyHeight.sp,
            alignment: Alignment.center,
            child: Icon(icon, size: _keyIconSize.sp, color: color != null ? Colors.white : p.text(Colors.black87)),
          ),
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final FontWeight? fontWeight;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.textColor,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final p = SalesCalcPalette.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.sp),
      child: Material(
        color: p.raised(Colors.white),
        borderRadius: BorderRadius.circular(8.r),
        elevation: 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: onTap,
          child: Container(
            height: _keyHeight.sp,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: _keyFontSize.sp,
                fontWeight: fontWeight ?? FontWeight.w500,
                color: textColor ?? p.text(Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:pdaftar_sales_calc/pdaftar_sales_calc.dart'
    show SalesCalcPackage;

import '../blocs/sales_calc_bloc/sales_calc_bloc.dart';
import '../blocs/sales_calc_bloc/sales_calc_event.dart';
import '../blocs/sales_calc_bloc/sales_calc_state.dart';
import '../sales_calc_palette.dart';

/// ⚙️ Sozlamalar bottom sheet for the Sotuv Kalkulyator page.
///
/// Extracted verbatim from `_SalesCalcListPageState._showSettings` so the
/// page file stops growing; expects a [SalesCalcBloc] above it in the
/// tree (the page passes its own via `BlocProvider.value`).
///
/// NOTE: strings are hardcoded Uzbek on purpose — the whole
/// `pdaftar_sales_calc` package predates l10n and every sibling widget
/// follows the same pattern.
class SalesCalcSettingsSheet extends StatelessWidget {
  const SalesCalcSettingsSheet({super.key, this.stockLockText = 'O‘chirish uchun avval birlikli satrlarni olib tashlang.'});
  final String stockLockText;

  static const _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SalesCalcBloc>();
    final p = SalesCalcPalette.of(context);
    return BlocBuilder<SalesCalcBloc, SalesCalcState>(
      builder: (context, state) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.sp,
                  height: 4.sp,
                  margin: EdgeInsets.only(bottom: 12.sp),
                  decoration: BoxDecoration(
                    color: p.handle(Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Sozlamalar',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.sp),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Nomi ustunini ko'rsatish",
                  style: TextStyle(fontSize: 15.sp),
                ),
                subtitle: Text(
                  "Har bir qator uchun nomi/izoh maydoni",
                  style:
                      TextStyle(
                      fontSize: 12.sp,
                      color: p.textSecondary(Colors.grey.shade600)),
                ),
                activeThumbColor: _purple,
                value: state.showLabels,
                onChanged: (_) => bloc.add(const ToggleShowLabels()),
              ),
              // "Skladdan kamaytirish" — sotuvda mahsulotga BOG'LANGAN
              // (autocomplete orqali tanlangan) qatorlar soni skladdan
              // ayiriladi; qo'lda yozilgan qatorlar jim o'tkaziladi.
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Skladdan kamaytirish",
                  style: TextStyle(fontSize: 15.sp),
                ),
                subtitle: Text(
                  state.hasStructuredItems
                      ? stockLockText
                      : "Sotuv saqlanganda mahsulotga bog'langan qatorlar "
                          "skladdan ayiriladi",
                  style:
                      TextStyle(
                      fontSize: 12.sp,
                      color: p.textSecondary(Colors.grey.shade600)),
                ),
                activeThumbColor: _purple,
                value: state.deductStock || state.hasStructuredItems,
                onChanged: state.hasStructuredItems
                    ? null
                    : (_) => bloc.add(const ToggleDeductStock()),
              ),
              Divider(height: 20.sp),
              Text(
                "Ro'yxatlar davri",
                style: TextStyle(fontSize: 15.sp),
              ),
              SizedBox(height: 4.sp),
              Text(
                "Yuqoridagi panelda oxirgi necha kunlik ro'yxatlar ko'rsatiladi",
                style: TextStyle(
                      fontSize: 12.sp,
                      color: p.textSecondary(Colors.grey.shade600)),
              ),
              SizedBox(height: 10.sp),
              // Pref lives outside bloc state → StatefulBuilder gives
              // the chips a local rebuild on selection; the list
              // refetch happens through the normal LoadSalesCalcLists
              // path which re-reads the pref.
              StatefulBuilder(
                builder: (context, setSheetState) {
                  final current = SalesCalcPackage.listDays;
                  Widget chip(int days, String label) => ChoiceChip(
                        label: Text(label, style: TextStyle(fontSize: 13.sp)),
                        selected: current == days,
                        selectedColor: p.accentTint(const Color(0xFFEDE9FE)),
                        onSelected: (_) {
                          SalesCalcPackage.listDays = days;
                          setSheetState(() {});
                          bloc.add(const LoadSalesCalcLists());
                        },
                      );
                  return Wrap(
                    spacing: 8.sp,
                    children: [
                      chip(7, '7 kun'),
                      chip(30, '30 kun'),
                      chip(90, '90 kun'),
                      chip(0, 'Hammasi'),
                    ],
                  );
                },
              ),
              SizedBox(height: 8.sp),
            ],
          ),
        ),
      ),
    );
  }
}

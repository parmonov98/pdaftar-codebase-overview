import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/sales_calc_list.dart';
import '../blocs/sales_calc_bloc/sales_calc_bloc.dart';
import '../blocs/sales_calc_bloc/sales_calc_state.dart';
import '../sales_calc_palette.dart';

enum _SheetSort { date, sumDesc, sumAsc }

/// Vertical browser for the sales lists with local filters: date
/// range, sort by total, and client (stamped on a list when its sale
/// is saved as a debt). Filtering is purely client-side — the lists
/// are already in the bloc, no extra fetches. Shown from the tab
/// strip's stacked-view button; the host page passes navigation
/// callbacks so this widget stays free of the page's controller
/// bookkeeping.
class SalesCalcListsSheet extends StatefulWidget {
  const SalesCalcListsSheet({
    super.key,
    required this.onPick,
    required this.onLongPressList,
    required this.formatNumber,
  });

  final void Function(int listId) onPick;
  final void Function(SalesCalcList list) onLongPressList;
  final String Function(double value) formatNumber;

  @override
  State<SalesCalcListsSheet> createState() => _SalesCalcListsSheetState();
}

class _SalesCalcListsSheetState extends State<SalesCalcListsSheet> {
  static const _purple = Color(0xFF7C3AED);

  /// Dark-mode colours (#649); light values pass through untouched.
  SalesCalcPalette get _p => SalesCalcPalette.of(context);
  static final _dateFmt = DateFormat('dd.MM.yyyy HH:mm');
  static final _rangeFmt = DateFormat('dd.MM');

  DateTimeRange? _range;
  _SheetSort _sort = _SheetSort.date;
  int? _clientId;
  String? _clientName;

  List<SalesCalcList> _visibleLists(List<SalesCalcList> all) {
    final out = all.where((l) {
      if (_range != null) {
        final u = l.updatedAt?.toLocal();
        if (u == null) return false;
        final day = DateTime(u.year, u.month, u.day);
        final start = DateUtils.dateOnly(_range!.start);
        final end = DateUtils.dateOnly(_range!.end);
        if (day.isBefore(start) || day.isAfter(end)) return false;
      }
      if (_clientId != null && l.clientId != _clientId) return false;
      return true;
    }).toList();
    switch (_sort) {
      case _SheetSort.sumDesc:
        out.sort((a, b) => b.total.compareTo(a.total));
      case _SheetSort.sumAsc:
        out.sort((a, b) => a.total.compareTo(b.total));
      case _SheetSort.date:
        // Server order is already updated_at desc.
        break;
    }
    return out;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: _purple, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _cycleSort() {
    setState(() {
      _sort = switch (_sort) {
        _SheetSort.date => _SheetSort.sumDesc,
        _SheetSort.sumDesc => _SheetSort.sumAsc,
        _SheetSort.sumAsc => _SheetSort.date,
      };
    });
  }

  /// Distinct clients present in the loaded lists — the filter only
  /// offers values that can actually match something.
  List<({int id, String name})> _clientsOf(List<SalesCalcList> lists) {
    final seen = <int>{};
    final out = <({int id, String name})>[];
    for (final l in lists) {
      final id = l.clientId;
      if (id == null || !seen.add(id)) continue;
      out.add((id: id, name: l.clientName ?? '#$id'));
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// [onTap] == null renders the chip without its own InkWell so an
  /// enclosing gesture owner (the client chip's PopupMenuButton) gets
  /// the tap instead of it being swallowed here.
  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    final body = Container(
        padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: active
              ? _p.accentTint(const Color(0xFFEDE9FE))
              : _p.raised(Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: active ? _p.accent(_purple) : _p.border(Colors.grey.shade300),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14.sp,
                color: active
                    ? _p.accent(_purple)
                    : _p.textSecondary(Colors.grey.shade600)),
            SizedBox(width: 4.sp),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? _p.accent(_purple)
                    : _p.textSecondary(Colors.grey.shade700),
              ),
            ),
            if (active && onClear != null) ...[
              SizedBox(width: 4.sp),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 14.sp, color: _p.accent(_purple)),
              ),
            ],
          ],
        ),
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: body,
    );
  }

  String get _sortLabel => switch (_sort) {
        _SheetSort.date => 'Sana',
        _SheetSort.sumDesc => 'Summa ↓',
        _SheetSort.sumAsc => 'Summa ↑',
      };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesCalcBloc, SalesCalcState>(
      builder: (context, state) {
        final clients = _clientsOf(state.lists);
        final lists = _visibleLists(state.lists);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.sp,
                    height: 4.sp,
                    margin: EdgeInsets.only(top: 12.sp, bottom: 8.sp),
                    decoration: BoxDecoration(
                      color: _p.handle(Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
                  child: Text(
                    "Ro'yxatlar",
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  ),
                ),
                // ── Filters: date range · sort · client ──
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(
                          icon: Icons.calendar_today_outlined,
                          label: _range == null
                              ? 'Sana'
                              : '${_rangeFmt.format(_range!.start)}–${_rangeFmt.format(_range!.end)}',
                          active: _range != null,
                          onTap: _pickRange,
                          onClear: () => setState(() => _range = null),
                        ),
                        SizedBox(width: 8.sp),
                        _filterChip(
                          icon: Icons.swap_vert,
                          label: _sortLabel,
                          active: _sort != _SheetSort.date,
                          onTap: _cycleSort,
                          onClear: () =>
                              setState(() => _sort = _SheetSort.date),
                        ),
                        if (clients.isNotEmpty) ...[
                          SizedBox(width: 8.sp),
                          PopupMenuButton<int?>(
                            onSelected: (id) => setState(() {
                              _clientId = id;
                              _clientName = id == null
                                  ? null
                                  : clients
                                      .firstWhere((c) => c.id == id)
                                      .name;
                            }),
                            itemBuilder: (context) => [
                              const PopupMenuItem<int?>(
                                value: null,
                                child: Text('Hammasi'),
                              ),
                              for (final c in clients)
                                PopupMenuItem<int?>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            child: _filterChip(
                              icon: Icons.person_outline,
                              label: _clientName ?? 'Mijoz',
                              active: _clientId != null,
                              // No onTap: PopupMenuButton owns the tap.
                              onClear: () => setState(() {
                                _clientId = null;
                                _clientName = null;
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: lists.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(32.sp),
                          child: Center(
                            child: Text(
                              'Hech narsa topilmadi',
                              style: TextStyle(
                                  fontSize: 13.sp, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.sp, vertical: 8.sp),
                          itemCount: lists.length,
                          separatorBuilder: (_, __) => SizedBox(height: 6.sp),
                          itemBuilder: (context, index) =>
                              _listRow(lists[index], state),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _listRow(SalesCalcList list, SalesCalcState state) {
    final isActive = list.id == state.activeListId;
    final updated = list.updatedAt;
    final parts = <String>[
      '${list.itemsCount} ta',
      if (updated != null) _dateFmt.format(updated.toLocal()),
      if (list.clientName != null && list.clientName!.isNotEmpty)
        list.clientName!,
    ];
    return Material(
      color: isActive
          ? _p.accentTint(const Color(0xFFF3F0FF))
          : _p.raised(Colors.grey.shade50),
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => widget.onPick(list.id),
        onLongPress: () => widget.onLongPressList(list),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
          child: Row(
            children: [
              Icon(
                isActive
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18.sp,
                color: isActive
                    ? _p.accent(_purple)
                    : _p.textSecondary(Colors.grey.shade400),
              ),
              SizedBox(width: 10.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name ?? '#${list.id}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? _p.accent(_purple) : _p.text(Colors.black87),
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      parts.join(' · '),
                      style: TextStyle(
                          fontSize: 11.sp,
                          color: _p.textSecondary(Colors.grey.shade600)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                widget.formatNumber(list.total),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _p.accent(_purple) : _p.text(Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

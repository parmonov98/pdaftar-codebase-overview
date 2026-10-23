// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:auto_route/auto_route.dart' as _i2;
import 'package:flutter/material.dart' as _i3;
import 'package:pdaftar_sales_calc/src/presentation/pages/sales_calc_list_page.dart'
    as _i1;

abstract class $SalesCalcModule extends _i2.AutoRouterModule {
  @override
  final Map<String, _i2.PageFactory> pagesMap = {
    SalesCalcListRoute.name: (routeData) {
      final args = routeData.argsAs<SalesCalcListRouteArgs>(
          orElse: () => const SalesCalcListRouteArgs());
      return _i2.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.SalesCalcListPage(
          key: args.key,
          initialClientId: args.initialClientId,
          initialClientName: args.initialClientName,
          initialListId: args.initialListId,
          startWithNewList: args.startWithNewList,
          onSaveAsDebt: args.onSaveAsDebt,
          onPickClient: args.onPickClient,
          onOpenLinkedDebt: args.onOpenLinkedDebt,
          isSalesToDebtAllowed: args.isSalesToDebtAllowed,
          onLockedAttempt: args.onLockedAttempt,
        ),
      );
    }
  };
}

/// generated route for
/// [_i1.SalesCalcListPage]
class SalesCalcListRoute extends _i2.PageRouteInfo<SalesCalcListRouteArgs> {
  SalesCalcListRoute({
    _i3.Key? key,
    int? initialClientId,
    String? initialClientName,
    int? initialListId,
    bool startWithNewList = false,
    _i4.Future<int?> Function(
      _i3.BuildContext,
      _i1.SalesCalcSaveDebtArgs,
    )? onSaveAsDebt,
    _i4.Future<({int id, String name})?> Function(_i3.BuildContext)?
        onPickClient,
    void Function(
      _i3.BuildContext, {
      int? clientId,
      String? clientName,
      int debtId,
    })? onOpenLinkedDebt,
    bool isSalesToDebtAllowed = true,
    void Function()? onLockedAttempt,
    List<_i2.PageRouteInfo>? children,
  }) : super(
          SalesCalcListRoute.name,
          args: SalesCalcListRouteArgs(
            key: key,
            initialClientId: initialClientId,
            initialClientName: initialClientName,
            initialListId: initialListId,
            startWithNewList: startWithNewList,
            onSaveAsDebt: onSaveAsDebt,
            onPickClient: onPickClient,
            onOpenLinkedDebt: onOpenLinkedDebt,
            isSalesToDebtAllowed: isSalesToDebtAllowed,
            onLockedAttempt: onLockedAttempt,
          ),
          initialChildren: children,
        );

  static const String name = 'SalesCalcListRoute';

  static const _i2.PageInfo<SalesCalcListRouteArgs> page =
      _i2.PageInfo<SalesCalcListRouteArgs>(name);
}

class SalesCalcListRouteArgs {
  const SalesCalcListRouteArgs({
    this.key,
    this.initialClientId,
    this.initialClientName,
    this.initialListId,
    this.startWithNewList = false,
    this.onSaveAsDebt,
    this.onPickClient,
    this.onOpenLinkedDebt,
    this.isSalesToDebtAllowed = true,
    this.onLockedAttempt,
  });

  final _i3.Key? key;

  final int? initialClientId;

  final String? initialClientName;

  final int? initialListId;

  final bool startWithNewList;

  final _i4.Future<int?> Function(
    _i3.BuildContext,
    _i1.SalesCalcSaveDebtArgs,
  )? onSaveAsDebt;

  final _i4.Future<({int id, String name})?> Function(_i3.BuildContext)?
      onPickClient;

  final void Function(
    _i3.BuildContext, {
    int? clientId,
    String? clientName,
    int debtId,
  })? onOpenLinkedDebt;

  final bool isSalesToDebtAllowed;

  final void Function()? onLockedAttempt;

  @override
  String toString() {
    return 'SalesCalcListRouteArgs{key: $key, initialClientId: $initialClientId, initialClientName: $initialClientName, initialListId: $initialListId, startWithNewList: $startWithNewList, onSaveAsDebt: $onSaveAsDebt, onPickClient: $onPickClient, onOpenLinkedDebt: $onOpenLinkedDebt, isSalesToDebtAllowed: $isSalesToDebtAllowed, onLockedAttempt: $onLockedAttempt}';
  }
}

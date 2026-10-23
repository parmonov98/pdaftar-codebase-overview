import 'package:flutter/material.dart';

String formatRemainingSms(
  int left,
  String Function(int count) localize,
) =>
    localize(left < 0 ? 0 : left);

Color smsBalanceColor({required int left, required int total}) {
  final safeLeft = left < 0 ? 0 : left;
  final ratio = total > 0 ? safeLeft / total : 0.0;
  if (ratio > 0.5) return const Color(0xFF4CAF50);
  if (safeLeft > 10) return const Color(0xFFFFA726);
  return const Color(0xFFF44336);
}

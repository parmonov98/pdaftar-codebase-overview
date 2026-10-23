import 'package:flutter/material.dart';
import 'package:pdaftaruz/service/telegram/owner_telegram_link_service.dart';

/// Wallet top-up entry point.
///
/// Payments-policy compliance (Google Play Payments policy / App Store
/// Guideline 3.1.1): the app must NOT lead users to a payment method other
/// than the store's own billing system. Google rejected the update on
/// 2026-07-13 because the old in-app top-up opened pdaftar.uz → Payme/Click.
///
/// Wallet top-up is now funded OUTSIDE the app — this opens @pDaftarBot, where
/// the owner tops up. In-app SMS / tariff / subscription purchases still spend
/// the wallet balance (internal credit), so those stay in-app.
class ProfileTopUpBottomSheet {
  static Future<void> open(BuildContext context) async {
    await OwnerTelegramLinkService.instance.openBot(context, needsLinking: true);
  }
}

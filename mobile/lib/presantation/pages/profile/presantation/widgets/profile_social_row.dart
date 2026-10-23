import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Social-links row at the bottom of the Profil menu (Telegram, Instagram,
/// YouTube, phone call). Extracted from [ProfilePageMenu] — it is fully
/// static, so as a `const` child it never rebuilds with the rest of the
/// menu during the first-open API burst.
class ProfileSocialRow extends StatelessWidget {
  const ProfileSocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(
          context,
          icon: Assets.telegramSvg,
          onTap: () => launchExternal(Assets.telegramChannelLink),
        ),
        _buildSocialButton(
          context,
          icon: Assets.instagramSvg,
          onTap: () => launchExternal(Assets.instagramAccountLink),
        ),
        _buildSocialButton(
          context,
          icon: Assets.youtubeSvg,
          onTap: () => launchExternal(Assets.youtubeChannelLink),
        ),
        _buildSocialButton(
          context,
          onTap: () async {
            // iOS: telprompt:// shows confirmation dialog;
            // Android: tel:// goes straight to dialer.
            const phoneNumber = "+998952212144";
            final url = Platform.isIOS
                ? "telprompt://$phoneNumber"
                : "tel:$phoneNumber";
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            } else {
              launchUrlString("tel://$phoneNumber");
            }
          },
        ),
      ],
    );
  }

  /// Open an external URL via the platform's url_launcher. Falls back to a
  /// no-op if the link can't be resolved (matches the previous behaviour
  /// of swallowing errors silently rather than surfacing them to the user
  /// — these social links are nice-to-haves). Public + static so the
  /// support section's "Telegram channel" row shares the same cascade.
  static Future<void> launchExternal(String link) async {
    // Try native app deep-link first, fall back to browser
    final appUri = _toAppUri(link);
    if (appUri != null && await canLaunchUrl(Uri.parse(appUri))) {
      await launchUrl(Uri.parse(appUri));
      return;
    }
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Converts well-known https URLs to their native app URI schemes.
  static String? _toAppUri(String link) {
    // t.me/channel  →  tg://resolve?domain=channel
    if (link.startsWith('https://t.me/+')) {
      final hash = link.replaceFirst('https://t.me/+', '');
      return 'tg://join?invite=$hash';
    }
    if (link.startsWith('https://t.me/')) {
      final domain = link.replaceFirst('https://t.me/', '');
      return 'tg://resolve?domain=$domain';
    }
    // youtube.com/@handle  →  vnd.youtube://www.youtube.com/@handle
    if (link.contains('youtube.com')) {
      return link.replaceFirst('https://', 'vnd.youtube://');
    }
    return null;
  }

  /// Square social-link button used in the row (Telegram channel,
  /// Instagram, phone). When [icon] is null, renders a circular green
  /// "Call" button instead.
  Widget _buildSocialButton(
    BuildContext context, {
    final String? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: icon != null
            ? CustomSvgWidgetAsset(
                icon,
                blendMode: BlendMode.dst,
                size: 24.sp,
              )
            : CustomButtonWidget(
                title: 'Call',
                backgroundColor: AppColors.green,
                disabled: false,
                icon: CustomSvgWidgetAsset(
                  Assets.phoneIconSvg,
                  size: 24.sp,
                ),
                isLoading: false,
                onTap: onTap,
              ).circularButton(context),
      ),
    );
  }
}

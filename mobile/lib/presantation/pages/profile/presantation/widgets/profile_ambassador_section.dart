import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_row.dart';
import 'package:pdaftaruz/presantation/pages/profile/presantation/widgets/settings_section.dart';
import 'package:pdaftaruz/presantation/pages/social_tasks/presantation/social_tasks_list_page.dart';
import 'package:pdaftaruz/presantation/pages/social_tasks/riverpod/social_task_provider.dart';
import 'package:pdaftaruz/presantation/pages/ugc/data/ugc_submission_response.dart';
import 'package:pdaftaruz/presantation/pages/ugc/presantation/riverpod/ugc_notifier.dart';
import 'package:pdaftaruz/presantation/pages/ugc/presantation/ugc_campaign_page.dart';

/// UGC "Ambassador" section (Vazifalar + Video yuborish rows with the
/// YANGI pill), extracted from [ProfilePageMenu].
///
/// Perf: the two remaining-count badges watch [socialTaskProvider] and
/// [ugcProvider]. Those used to be inline `ref.watch` calls in the huge
/// menu build, so every task/campaign/submission load re-ran the whole
/// ~700-line profile build. Scoped here, they rebuild only this section.
class ProfileAmbassadorSection extends ConsumerWidget {
  const ProfileAmbassadorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eligibility (account age, cooldown, etc.) is enforced on the page
    // itself, not at the menu level, so new users can still discover the
    // program. The "YANGI" pill is overlaid via a Stack so the existing
    // SettingsSection stays unchanged.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SettingsSection(
          title: AppLocalization.getText(context)?.ugc_program_title ??
              'Ambassador',
          children: [
            SettingsRow(
              title: AppLocalization.getText(context)?.social_tasks_title ??
                  'Vazifalar',
              iconAsset: Assets.checkboxIconSvg,
              // Remaining tasks the user hasn't completed yet.
              // Decrements optimistically as they submit, since
              // the notifier bumps `userCompletionFlag` in place.
              notificationCount: ref.watch(
                socialTaskProvider.select(
                  (s) => s.tasks.where((t) => !t.isCompletedByUser).length,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SocialTasksListPage(),
                ),
              ),
            ),
            SettingsRow(
              title: AppLocalization.getText(context)?.ugc_record_cta ??
                  'Video yuborish',
              iconAsset: Assets.cameraIconSvg,
              // Remaining UGC templates the user can still
              // submit to in the active campaign. A non-
              // rejected submission consumes that template
              // slot; a rejection re-opens it.
              notificationCount: ref.watch(
                ugcProvider.select((s) {
                  final templates = s.campaign?.templates ?? [];
                  if (templates.isEmpty) return 0;
                  final consumed = s.submissions
                      .where(
                          (sub) => sub.status != UgcSubmission.statusRejected)
                      .map((sub) => sub.templateType)
                      .toSet();
                  return templates
                      .where((t) => !consumed.contains(t.templateType))
                      .length;
                }),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UgcCampaignPage(),
                ),
              ),
            ),
          ],
        ),
        // YANGI pill — positioned to sit next to the uppercase section
        // header (top offset matches SettingsSection's title padding 12.h).
        Positioned(
          top: 14.h,
          right: 16.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.deepPurple.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              AppLocalization.getText(context)?.ugc_new_badge ?? 'YANGI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

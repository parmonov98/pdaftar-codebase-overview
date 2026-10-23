import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class SmsProgressBar extends StatelessWidget {
  final int leftSms;
  final int totalSms;
  final String? tariffName;

  const SmsProgressBar({
    super.key,
    required this.leftSms,
    required this.totalSms,
    this.tariffName,
  });

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero and handle edge cases
    final int safeLeftSms = leftSms < 0 ? 0 : leftSms;
    final int safeTotalSms = totalSms <= 0 ? 1 : totalSms;
    
    // Make sure leftSms is not greater than totalSms
    final int adjustedLeftSms = safeLeftSms > safeTotalSms ? safeTotalSms : safeLeftSms;
    
    // Calculate percentage of SMS remaining
    final double percentage = adjustedLeftSms / safeTotalSms;
    
    // Get color based on the specific thresholds
    Color barColor = _getSmsBarColor(adjustedLeftSms, percentage);
    
    // Get the same background color used in BusinessProgressBar
    final Color emptyBgColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade200;

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppText(
                    "${AppLocalization.getText(context)?.sms_limit}",
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  InkWell(
                    onTap: (){
                      AppHelpers.appAlertDialog(context: context,
                        isQuestionMark: false,
                        title: "${AppLocalization.getText(context)?.sms_limit_title}",
                        content: "${AppLocalization.getText(context)?.sms_limit_content}"
                      );
                    },
                    child: CustomSvgWidgetAsset(
                      Assets.infoIconSvg,
                      color: context.palette.accent,
                    ),
                  )
                ],
              ),
              AppText(
                "$adjustedLeftSms/$safeTotalSms",
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: context.palette.accent,
              ),
            ],
          ),
          8.verticalSpace,
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width based on available width
              final double availableWidth = constraints.maxWidth;
              final double filledWidth = availableWidth * percentage;
              
              return GestureDetector(
                onTap: () {
                  // Open SMS History Page when progress bar is clicked
                  AppNavigator.push(const SmsHistoryRoute());
                },
                child: Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        // Background (empty state) - full width
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: emptyBgColor,
                        ),
                        // Filled portion with solid color based on thresholds
                        if (adjustedLeftSms > 0)
                          Positioned(
                            left: 0,
                            width: filledWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: barColor, // Solid color based on thresholds
                                borderRadius: percentage >= 0.99 
                                  ? BorderRadius.circular(4)
                                  : const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Get SMS bar color based on the specific thresholds
  Color _getSmsBarColor(int smsLeft, double percentage) {
    // Green when more than 50% of SMS limit remains
    if (percentage > 0.5) {
      return const Color(0xFF4CAF50); // Green
    } 
    // Warning color when less than 50% but more than 10 SMS remain
    else if (smsLeft > 10) {
      return const Color(0xFFFFA726); // Orange
    } 
    // Red when 10 or fewer SMS remain
    else {
      return const Color(0xFFF44336); // Red
    }
  }
} 
import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class ClientReportProgressBar extends StatelessWidget {
  final int clientReportCount;
  final int clientReportLimit;
  final int clientReportsLeft;

  const ClientReportProgressBar({
    super.key,
    required this.clientReportCount,
    required this.clientReportLimit,
    required this.clientReportsLeft,
  });

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero and handle edge cases
    final int safeClientReportLimit = clientReportLimit <= 0 ? 1 : clientReportLimit;
    
    // Make sure reports left is not greater than limit
    final int safeReportsLeft = clientReportsLeft < 0 ? 0 : 
                             (clientReportsLeft > safeClientReportLimit ? safeClientReportLimit : clientReportsLeft);
    
    // Calculate percentage of client reports remaining
    final double remainingPercentage = safeReportsLeft / safeClientReportLimit;
    
    // Get color based on the remaining reports and percentage
    Color barColor = _getClientReportBarColor(safeReportsLeft, remainingPercentage);
    
    // Get the same background color used in other ProgressBars
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
              Expanded(
                child: AppText(
                  AppLocalization.getText(context)?.client_report_limit ?? 'Client report limit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              AppText(
                "$safeReportsLeft/$safeClientReportLimit",
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: context.palette.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width based on available width
              final double availableWidth = constraints.maxWidth;
              final double filledWidth = availableWidth * remainingPercentage;
              
              return Container(
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
                      // Background (empty state)
                      Container(
                        width: double.infinity,
                        height: 10,
                        color: emptyBgColor,
                      ),
                      // Filled portion with solid color based on thresholds
                      if (remainingPercentage > 0)
                        Container(
                          width: filledWidth,
                          height: 10,
                          decoration: BoxDecoration(
                            color: barColor, // Solid color based on thresholds
                            borderRadius: remainingPercentage >= 0.99 
                              ? BorderRadius.circular(4)
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Get client report bar color based on the remaining reports and percentage
  Color _getClientReportBarColor(int reportsLeft, double remainingPercentage) {
    // Green when more than 50% of limit remains
    if (remainingPercentage > 0.5) {
      return const Color(0xFF4CAF50); // Green
    } 
    // Warning color when less than 50% but more than 2 reports remain
    else if (reportsLeft > 2) {
      return const Color(0xFFFFA726); // Orange
    } 
    // Red when 2 or fewer reports remain
    else {
      return const Color(0xFFF44336); // Red
    }
  }
} 
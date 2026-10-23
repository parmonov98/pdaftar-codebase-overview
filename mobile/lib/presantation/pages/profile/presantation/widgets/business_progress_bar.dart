import 'package:pdaftaruz/core/imports/imports.dart';
import 'package:pdaftaruz/presantation/themes/app_palette.dart';

class BusinessProgressBar extends StatelessWidget {
  final int businessesCount;
  final int businessLimit;

  const BusinessProgressBar({
    super.key,
    required this.businessesCount,
    required this.businessLimit,
  });

  @override
  Widget build(BuildContext context) {
    // Prevent division by zero and handle edge cases
    final int safeBusinessesCount = businessesCount < 0 ? 0 : businessesCount;
    final int safeBusinessLimit = businessLimit <= 0 ? 1 : businessLimit;
    
    // Make sure businessesCount is not greater than businessLimit
    final int adjustedBusinessesCount = safeBusinessesCount > safeBusinessLimit ? safeBusinessLimit : safeBusinessesCount;
    
    // Calculate percentage of businesses used
    final double percentage = adjustedBusinessesCount / safeBusinessLimit;
    
    // Determine color based on percentage - using a more gradual approach
    Color progressColor = _getColorByPercentage(percentage);
    

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
                  AppLocalization.getText(context)?.business_limit ?? 'Business limit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 4.w),
              AppText(
                "$adjustedBusinessesCount/$safeBusinessLimit",
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: context.palette.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate ideal brick size based on available width
              final double availableWidth = constraints.maxWidth;
              // Determine whether to use condensed view (for many bricks)
              final bool useCondensedView = safeBusinessLimit > 5;
              
              return Container(
                height: 10, // Match SMS bar height
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
                  child: useCondensedView 
                    ? _buildCondensedBusinessBricks(
                        context,
                        adjustedBusinessesCount,
                        safeBusinessLimit,
                        progressColor,
                        availableWidth,
                        percentage,
                      )
                    : _buildBusinessBricks(
                        context,
                        adjustedBusinessesCount,
                        safeBusinessLimit,
                        progressColor,
                        availableWidth,
                        percentage,
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Get a color based on percentage with a more gradual transition
  Color _getColorByPercentage(double percentage) {
    // Define color stops for the gradient
    if (percentage <= 0.3) {
      // Bright green for very low usage (0-30%)
      return const Color(0xFF4CAF50);
    } else if (percentage <= 0.5) {
      // Lime green for low-medium usage (30-50%)
      return const Color(0xFF8BC34A);
    } else if (percentage <= 0.7) {
      // Yellow-green for medium usage (50-70%)
      return const Color(0xFFCDDC39);
    } else if (percentage <= 0.8) {
      // Yellow for medium-high usage (70-80%)
      return const Color(0xFFFFEB3B);
    } else if (percentage <= 0.9) {
      // Orange for high usage (80-90%)
      return const Color(0xFFFF9800);
    } else if (percentage < 1.0) {
      // Dark orange for very high usage (90-99%)
      return const Color(0xFFFF5722);
    } else {
      // Red for maxed out usage (100%)
      return const Color(0xFFF44336);
    }
  }

  // Build brick-style business blocks (for smaller number of businesses)
  Widget _buildBusinessBricks(
    BuildContext context,
    int businessesCount,
    int businessLimit,
    Color progressColor,
    double availableWidth,
    double percentage,
  ) {
    if (businessLimit == 0) return const SizedBox.shrink();
    
    // Calculate the filled width percentage
    final double filledWidth = availableWidth * percentage;
    
    // Use a solid green color
    final Color greenColor = const Color(0xFF4CAF50);
    
    return Stack(
      children: [
        // Background (empty state)
        Container(
          width: double.infinity,
          height: 10,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
        // Filled portion with solid green color
        if (businessesCount > 0)
          Container(
            width: filledWidth,
            height: 10,
            decoration: BoxDecoration(
              color: greenColor, // Solid green color
              borderRadius: percentage >= 1.0 
                ? BorderRadius.circular(4)
                : const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
            ),
          ),
      ],
    );
  }
  
  // Build condensed brick representation (SMS-style)
  Widget _buildCondensedBusinessBricks(
    BuildContext context,
    int businessesCount,
    int businessLimit,
    Color progressColor,
    double availableWidth,
    double percentage,
  ) {
    // For SMS-style, we'll reuse the regular progress bar implementation
    // but with the gradient approach
    return _buildBusinessBricks(
      context,
      businessesCount,
      businessLimit,
      progressColor,
      availableWidth,
      percentage,
    );
  }
}

// Helper function for min value
int min(int a, int b) => a < b ? a : b; 
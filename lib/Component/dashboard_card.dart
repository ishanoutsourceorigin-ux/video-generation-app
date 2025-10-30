import 'package:flutter/material.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String imagePath;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.width > 600;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // Responsive sizing
        final cardPadding = isTablet ? 20.0 : 16.0;
        final titleFontSize = isTablet ? 18.0 : 16.0;
        final valueFontSize = isTablet ? 28.0 : (isLandscape ? 20.0 : 24.0);
        final imageSize = isTablet ? 60.0 : (isLandscape ? 40.0 : 50.0);
        final containerPadding = isTablet ? 12.0 : 8.0;

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppColors.darkGreyColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.greyColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // SizedBox(height: isTablet ? 12 : 8),
              Flexible(
                child: Row(
                  children: [
                    Expanded(child: _buildValueText(value, valueFontSize)),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(containerPadding),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        imagePath,
                        width: imageSize,
                        height: imageSize,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.error,
                            size: imageSize,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Smart text builder that handles wrapping for time values
  Widget _buildValueText(String value, double fontSize) {
    // Check if value contains space and is likely a time format
    if (value.contains(' ') &&
        (value.contains('h') || value.contains('m') || value.contains('d'))) {
      // Split the value for potential wrapping
      final parts = value.split(' ');
      if (parts.length >= 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parts[0], // First part (e.g., "2h")
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (parts.length > 1)
              Text(
                parts.sublist(1).join(' '), // Remaining parts (e.g., "10min")
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 0.8, // Slightly smaller for second line
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        );
      }
    }

    // Default single line text for other values
    return Text(
      value,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

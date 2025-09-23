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
        final valueFontSize = isTablet ? 40.0 : (isLandscape ? 28.0 : 34.0);
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
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
}

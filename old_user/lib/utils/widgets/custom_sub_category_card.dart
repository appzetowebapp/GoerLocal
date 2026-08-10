import 'package:flutter/material.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';

class CustomSubCategoryCard extends StatelessWidget {
  final String categoryImage;
  final String categoryName;
  final BoxFit imageFit;

  const CustomSubCategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryImage,
    this.imageFit = BoxFit.contain
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> bgColors = [
      Color(0xFFE5F3FF), // Light Blue
      Color(0xFFFFF0F5), // Light Pink
      Color(0xFFF0FFF4), // Light Green
      Color(0xFFFFF5EB), // Light Orange
      Color(0xFFF3F0FF), // Light Purple
    ];
    
    // Simple way to get a consistent color for the same category name
    final int colorIndex = categoryName.length % bgColors.length;
    final Color bgColor = bgColors[colorIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the available space from grid
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        final borderRadius = 12.0;

        return SizedBox(
          width: cardWidth,
          height: cardHeight,
          child: Column(
            children: [
              Expanded(
                flex: 70,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: CustomImageContainer(imagePath:categoryImage, fit: imageFit, )
                  )
                ),
              ),
              SizedBox(height: 8,),
              Expanded(
                flex: 30,
                child: categoryNameWidget(
                    categoryName: categoryName,
                  cardWidth: cardWidth
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget categoryNameWidget ({
    required String categoryName, required double cardWidth}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: cardWidth * 0.05),
      child: Text(
        categoryName,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: _getResponsiveFontSize(cardWidth),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF131124),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  double _getResponsiveFontSize(double cardWidth) {
    // Calculate font size based on card width
    if (cardWidth >= 100) return 16;
    if (cardWidth >= 80) return 15;
    if (cardWidth >= 60) return 14;
    return 14;
  }
}

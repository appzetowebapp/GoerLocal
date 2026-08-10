import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:remixicon/remixicon.dart';
import 'package:hyper_local/config/theme.dart';

class AnimatedNotchedNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AnimatedNotchedNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AnimatedNotchedNavBar> createState() => _AnimatedNotchedNavBarState();
}

class _AnimatedNotchedNavBarState extends State<AnimatedNotchedNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dotAnimation;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dotAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(AnimatedNotchedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _lastIndex = oldWidget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = const Color.fromARGB(255, 12, 2, 108);
    final Color bgColor = isDark ? const Color.fromARGB(255, 12, 2, 108) : Colors.white;
    final double width = MediaQuery.of(context).size.width;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Total height = base height (70) + system navigation bar padding
    final double totalHeight = 70.w + bottomPadding;

    return Container(
      height: totalHeight,
      width: double.infinity,
      color: Colors.transparent,
      child: Stack( 
        clipBehavior: Clip.none, // Allow center button to overflow if needed
        children: [
          // Background Painter
          Positioned.fill( 
            top: 15.w,
            child: CustomPaint(
              painter: NotchedPainter(
                color: bgColor,
                isDark: isDark,
                bottomPadding: bottomPadding,
              ),
            ),
          ),

          // Sliding Dot
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double t = _controller.value;
              double startPos = _getIndexPosition(_lastIndex, width);
              double endPos = _getIndexPosition(widget.currentIndex, width);
              double currentPos = startPos + (endPos - startPos) * t;

              // Hide dot if center button is selected
              bool hideDot = widget.currentIndex == 2;
              
              return Positioned(
                left: currentPos - 2.w,
                bottom: 6.w + bottomPadding, // Adjusted for better visibility above the system bar
                child: Opacity(
                  opacity: hideDot ? 0 : 1,
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ), 
                  ),
                ),
              );
            },
          ),

          // Icons
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 5.w, // Lift icons slightly above the bottom
            child: SizedBox(
              height: 40.w, // Slightly taller for better touch targets
              child: Row(
                children: [
                  _buildNavItem(0, HeroiconsOutline.squares2x2, HeroiconsSolid.squares2x2, width),
                  _buildNavItem(1, HeroiconsOutline.buildingStorefront, HeroiconsSolid.buildingStorefront, width),
                  const Spacer(), // Space for center (Home)
                  _buildNavItem(3, HeroiconsOutline.bookmark, HeroiconsSolid.bookmark, width),
                  _buildNavItem(4, HeroiconsOutline.userCircle, HeroiconsSolid.userCircle, width),
                ],
              ),
            ),
          ),

          // Floating Center Button
          Positioned(
            top: 0,
            left: width / 2 - 32.w,
            child: GestureDetector(
              onTap: () => widget.onTap(2),
              child: AnimatedScale(
                scale: widget.currentIndex == 2 ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: bgColor,
                      width: 4.w,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: Image.asset(
                        'assets/images/app_logos/app-logo-light.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getIndexPosition(int index, double totalWidth) {
    double sectionWidth = totalWidth / 5;
    return (index * sectionWidth) + (sectionWidth / 2);
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, double totalWidth) {
    final bool isActive = widget.currentIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = Color.fromARGB(255, 12, 2, 108);
    final Color inactiveColor = isDark ? Colors.white38 : const Color.fromARGB(255, 116, 115, 115);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.translationValues(0, isActive ? -2.w : 0, 0),
              child: Icon(
                isActive ? solidIcon : outlineIcon,
                color: isActive ? activeColor : inactiveColor,
                size: 24.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotchedPainter extends CustomPainter {
  final Color color;
  final bool isDark;
  final double bottomPadding;

  NotchedPainter({
    required this.color, 
    required this.isDark,
    required this.bottomPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double cornerRadius = 25.w;
    double notchWidth = 90.w;
    double notchRadius = 35.w;

    Path path = Path();
    
    // Start at top-left
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    
    // Line to start of notch
    path.lineTo((size.width - notchWidth) / 2, 0);
    
    // Smooth entry into notch
    path.quadraticBezierTo(
      (size.width - notchWidth) / 2 + 15.w, 0,
      (size.width - notchWidth) / 2 + 22.w, 10.w,
    );
    
    // The main notch arc
    path.arcToPoint(
      Offset((size.width + notchWidth) / 2 - 22.w, 10.w),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    
    // Smooth exit from notch
    path.quadraticBezierTo(
      (size.width + notchWidth) / 2 - 15.w, 0,
      (size.width + notchWidth) / 2, 0,
    );

    // Line to top-right corner
    path.lineTo(size.width - cornerRadius, 0);
    
    // Top-right corner
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    
    // Right side
    path.lineTo(size.width, size.height);
    
    // Bottom (including padding)
    path.lineTo(0, size.height);
    
    // Left side
    path.lineTo(0, cornerRadius);
    
    path.close();

    if (!isDark) {
      canvas.drawShadow(path, Colors.black.withOpacity(0.12), 15, true);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}



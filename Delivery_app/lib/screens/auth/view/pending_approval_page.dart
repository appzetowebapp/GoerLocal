import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_button.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'dart:math' as math;

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  
  AnimationController? _rotationController;

  void _initAnimations() {
    if (_pulseController != null) return;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void initState() {
    super.initState();
    Global.isAccountApprovedNotifier.addListener(_onApprovalStatusChanged);
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAnimations();
  }

  @override
  void dispose() {
    Global.isAccountApprovedNotifier.removeListener(_onApprovalStatusChanged);
    _pulseController?.dispose();
    _rotationController?.dispose();
    super.dispose();
  }

  void _onApprovalStatusChanged() {
    if (mounted) {
      setState(() {
        if (Global.isAccountApprovedNotifier.value) {
          _pulseController?.stop();
          _rotationController?.stop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = context.isDarkMode;
    bool isApproved = Global.isAccountApprovedNotifier.value;

    return CustomScaffold(
      wantSafeArea: false,
      body: Container(
        width: double.infinity,
        decoration: isDark
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 10, 13, 155),
                    Color.fromARGB(255, 30, 35, 180),
                  ],
                ),
              ),
        child: Column(
          children: [
            // Top Section (Animated Icon)
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative background ripples
                  if (!isApproved) ...[
                    AnimatedBuilder(
                      animation: _pulseAnimation!,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation!.value * 1.5,
                          child: Container(
                            width: 150.w,
                            height: 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _pulseAnimation!,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation!.value * 1.2,
                          child: Container(
                            width: 150.w,
                            height: 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // Approval Confetti / Rays (if approved)
                  if (isApproved)
                    AnimatedBuilder(
                      animation: _rotationController!,
                      builder: (context, child) {
                        // Slow rotation of rays when approved
                        return Transform.rotate(
                          angle: _rotationController!.value * 2 * math.pi * 0.2, // slow rotation
                          child: Container(
                            width: 250.w,
                            height: 250.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.greenAccent.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // Main Icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 800),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(
                        scale: CurvedAnimation(
                            parent: animation, curve: Curves.elasticOut),
                        child: RotationTransition(
                          turns: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: isApproved
                        ? Container(
                            key: const ValueKey<bool>(true),
                            padding: EdgeInsets.all(20.w),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 100.sp,
                              color: Colors.green,
                            ),
                          )
                        : AnimatedBuilder(
                            key: const ValueKey<bool>(false),
                            animation: _pulseAnimation!,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation!.value,
                                child: Container(
                                  padding: EdgeInsets.all(20.w),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 80.sp,
                                    color: const Color.fromARGB(255, 10, 13, 155),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Bottom Section (Content Card)
            Expanded(
              flex: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkColor : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32.r),
                    topRight: Radius.circular(32.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: CustomText(
                        key: ValueKey(isApproved),
                        text: isApproved ? 'Approved!' : 'Pending Approval',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isApproved
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurface,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: CustomText(
                        key: ValueKey(isApproved),
                        text: isApproved
                            ? 'Your account has been successfully verified! You are now ready to start delivering.'
                            : 'Your registration is complete and is currently under review by our team. We will notify you once approved.',
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        height: 1.5,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Button / Loader
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: isApproved
                          ? CustomButton(
                              key: const ValueKey('login_btn'),
                              text: 'Go to Login',
                              onPressed: () async {
                                await Global.clearUserToken();
                                await Global.clearIdToken();
                                Global.isAccountApprovedNotifier.value = false;
                                if (context.mounted) {
                                  context.go(AppRoutes.login);
                                }
                              },
                            )
                          : Column(
                              key: const ValueKey('loading_indicator'),
                              children: [
                                SizedBox(
                                  width: 40.w,
                                  height: 40.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 10, 13, 155),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                CustomText(
                                  text: 'Please wait...',
                                  fontSize: 15,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

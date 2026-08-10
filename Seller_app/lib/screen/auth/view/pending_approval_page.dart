import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> with SingleTickerProviderStateMixin {
  Timer? _statusTimer;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _isApproved = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)
      ),
    );

    // Poll every 30 seconds
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkStatus();
    });

    // Listen for FCM messages to trigger immediate status check
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['action'] == 'seller_approved') {
        _setApprovedState();
      } else {
        _checkStatus();
      }
    });

    // Initial check after a short delay
    Future.delayed(const Duration(seconds: 2), _checkStatus);
  }
  
  void _setApprovedState() {
    if (mounted && !_isApproved) {
      setState(() {
        _isApproved = true;
      });
      _statusTimer?.cancel();
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messageSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final identifier = HiveStorage.registeredIdentifier;
    if (identifier == null || identifier.isEmpty) return;
    if (_isLoading) return; 

    try {
      setState(() { _isLoading = true; });
      final response = await _authRepository.checkRegistrationStatus(identifier);

      if (response is Map && response['success'] == true) {
        final data = response['data'];
        if (data != null && data is Map) {
          final canLogin = data['can_login'] == true;
          final isApproved = data['verification_status'] == 'approved';

          if (canLogin || isApproved) {
            _setApprovedState();
            if (mounted) {
              showCustomSnackbar(
                context: context,
                message: response['message']?.toString() ?? "Your seller account is approved. You can log in now.",
              );
            }
          }
        }
      }
    } catch (e) {
      log('Check status error: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;
    final size = MediaQuery.of(context).size;

    return CustomScaffold(
      showAppbar: false,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isApproved 
                    ? Colors.green.withValues(alpha: 0.2) 
                    : Colors.amber.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isApproved 
                    ? Colors.teal.withValues(alpha: 0.15) 
                    : Colors.orange.withValues(alpha: 0.15),
              ),
            ),
          ),
          
          // Blur Effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
          
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(UIUtils.gapLG(screenType)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isApproved ? _buildApprovedContent(theme, isDark) : _buildPendingContent(theme, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('pending'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Animated Pulse Icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 5 * _pulseAnimation.value,
                    )
                  ],
                ),
                child: const Icon(
                  TablerIcons.hourglass_high,
                  size: 70,
                  color: Colors.amber,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 50),
        
        // Glass Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Registration Submitted",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Animated Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Pending Approval",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                "Your seller account is currently under admin review. You will receive a notification once it is approved.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Check Status Button
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isLoading ? null : _checkStatus,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
                      Icon(TablerIcons.refresh, size: 22, color: theme.primaryColor),
                    const SizedBox(width: 12),
                    Text(
                      _isLoading ? "Checking..." : "Refresh Status",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildApprovedContent(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('approved'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        
        // Success Icon Animation
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  TablerIcons.circle_check_filled,
                  size: 80,
                  color: Colors.green,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 50),
        
        // Success Glass Card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Account Approved!",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Success Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      TablerIcons.discount_check_filled,
                      size: 18,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Ready to Sell",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                "Congratulations! Your seller account has been fully verified and approved. You can now log in to access your dashboard.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const Spacer(),
        
        // Go to Login Button with entrance animation
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: PrimaryButton(
            onPressed: () => context.go(AppRoutes.login),
            text: "Go to Login",
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

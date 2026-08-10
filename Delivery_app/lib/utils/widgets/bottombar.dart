import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../l10n/app_localizations.dart';
import '../../router/app_routes.dart';
import '../../../../config/colors.dart';

class BottomNavBar extends StatefulWidget {
  final Widget child;

  const BottomNavBar({super.key, required this.child});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const List<String> _routes = [
    AppRoutes.home,
    AppRoutes.feed,
    AppRoutes.pockets,
    AppRoutes.more,
  ];

  void _onItemTapped(int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    int selectedIndex = _routes.indexOf(currentRoute);
    if (selectedIndex == -1) selectedIndex = 0;

    return CustomScaffold(
      // The separated widget handles both iOS and Android natively
      bottomNavigationBar: FallBackBottomBar(
        routes: _routes,
        selectedIndex: selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: widget.child,
    );
  }
}

class FallBackBottomBar extends StatelessWidget {
  final List<String> routes;
  final int selectedIndex;
  final Function(int) onItemTapped; // Passed from parent

  const FallBackBottomBar({
    super.key,
    required this.routes,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(routes.length, (index) {
            final isSelected = index == selectedIndex;
            final route = routes[index];

            IconData icon;
            String label;

            switch (route) {
              case AppRoutes.home:
                icon = Icons.home;
                label = AppLocalizations.of(context)!.home;
                break;
              case AppRoutes.feed:
                icon = Icons.directions_bike;
                label = AppLocalizations.of(context)!.feed;
                break;
              case AppRoutes.pockets:
                icon = Icons.account_balance_wallet;
                label = AppLocalizations.of(context)!.pockets;
                break;
              case AppRoutes.more:
                icon = Icons.settings;
                label = AppLocalizations.of(context)!.settings;
                break;
              default:
                icon = Icons.home;
                label = AppLocalizations.of(context)!.home;
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onItemTapped(index), // Uses the parent's function
                child: Container(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Colors.grey[400],
                        size: (isTablet(context: context) ? 14 : 24).sp,
                      ),
                      CustomText(
                        text: label,
                        fontSize: sz(12, seprateTabletSize: 7),
                        fontWeight: FontWeight.w500,
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:hyper_local/utils/widgets/custom_appbar_without_navbar.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_text.dart';
import 'package:hyper_local/utils/widgets/custom_card.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_bloc.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_event.dart';
import 'package:hyper_local/screens/feed_page/bloc/my_orders_bloc/my_orders_state.dart';
import 'package:hyper_local/screens/feed_page/model/available_orders.dart';
import 'package:hyper_local/utils/currency_formatter.dart';
import 'package:hyper_local/utils/widgets/empty_state_widget.dart';
import 'package:hyper_local/utils/widgets/loading_widget.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/config/helper.dart';

class MyOrdersPage extends StatefulWidget {
  final String? initialTabStatus;

  const MyOrdersPage({super.key, this.initialTabStatus});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _statusTabs = [
    'assigned',
    'in_progress',
    'completed',
    'canceled',
  ];

  @override
  void initState() {
    super.initState();

    int initialIndex = 0;
    if (widget.initialTabStatus != null) {
      initialIndex = _statusTabs.indexOf(widget.initialTabStatus!);
      if (initialIndex == -1) {
        initialIndex = 0; // Default to first tab if status not found
      }
    }
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_handleTabSelection);
    _loadOrdersForTab(_statusTabs[initialIndex]);
  }

  void _handleTabSelection() {
    setState(() {
      // _currentTabIndex = _tabController.index; // This line is removed
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadOrdersForTab(String status) {
    context.read<MyOrdersBloc>().add(AllMyOrdersList(type: status));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBarWithoutNavbar(
        title: AppLocalizations.of(context)!.myOrders,
      ),
      body: Column(
        children: [
          // Custom Tab Bar with rounded pill buttons
          Container(
            height: (isTablet() ? 52 : 60).h,
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: (isTablet() ? 8 : 12).h,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusTabs.length,
              itemBuilder: (context, index) {
                final status = _statusTabs[index];
                final isSelected = _tabController.index == index;

                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                    context.read<MyOrdersBloc>().add(
                      AllMyOrdersList(type: status),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 12.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: (isTablet() ? 14 : 20).w,
                      vertical: 0.h,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.transparent
                                : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: CustomText(
                      text: _getStatusDisplayName(status),
                      fontSize: sz(13, seprateTabletSize: 10),
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                );
              },
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  _statusTabs.map((status) {
                    return _buildTabContent(status, context.isDarkMode);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String status, bool isDarkTheme) {
    return BlocBuilder<MyOrdersBloc, MyOrdersState>(
      builder: (context, state) {
        if (state.status == ApiStatus.loading && state.myOrders.isEmpty) {
          return const Center(child: LoadingWidget());
        } else if (state.status == ApiStatus.failed && state.myOrders.isEmpty) {
          return ErrorStateWidget(onRetry: () => _loadOrdersForTab(status));
        } else if (state.status == ApiStatus.success || state.isRefreshing) {
          final filteredOrders = _filterOrdersByStatus(state.myOrders, status);

          if (filteredOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: (isTablet() ? 48 : 64).r,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text:
                        '${AppLocalizations.of(context)!.no} ${_getStatusDisplayName(status).toLowerCase()} ${AppLocalizations.of(context)!.orders}',
                    fontSize: sz(16, seprateTabletSize: 12),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadOrdersForTab(status);
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(
                  order,
                  isDarkTheme,
                ).fadeAndSlideAnimation();
              },
            ),
          );
        }

        return const Center(child: LoadingWidget());
      },
    );
  }

  List<Orders> _filterOrdersByStatus(List<Orders> orders, String status) {
    return orders.where((order) {
      final orderStatus = order.status?.toLowerCase() ?? '';

      switch (status) {
        case 'assigned':
          return orderStatus == 'assigned';
        case 'in_progress':
          return orderStatus == 'preparing' ||
              orderStatus == 'ready' ||
              orderStatus == 'out_for_delivery';
        case 'completed':
          return orderStatus == 'delivered' || orderStatus == 'completed';
        case 'canceled':
          return orderStatus == 'canceled' || orderStatus == 'cancelled';
        default:
          return false;
      }
    }).toList();
  }

  Widget _buildOrderCard(Orders order, bool isDarkTheme) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: CustomCard(
        onTap: () {
          bool isDeliveryOrder = order.status?.toLowerCase() == 'delivered';

          context.push(
            AppRoutes.orderDetails,
            extra: {
              'orderId': order.id!,
              'from': isDeliveryOrder,
              'sourceTab': 1,
            },
          );
        },
        child: Padding(
          padding: EdgeInsets.all((isTablet() ? 12 : 16).w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text:
                          '${AppLocalizations.of(context)!.order} #${order.id ?? 'N/A'}',
                      fontSize: sz(16, seprateTabletSize: 12),
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.status ?? '',
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: CustomText(
                      text: _getLocalizedStatus(order.status ?? '', context),
                      fontSize: sz(12, seprateTabletSize: 9),
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(order.status ?? ''),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Delivery address
              if (order.shippingAddress1 != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: sz(16, seprateTabletSize: 12).sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: CustomText(
                        text:
                            '${order.shippingAddress1}, ${order.shippingAddress2 ?? ''}, ${order.shippingCity ?? ''}, ${order.shippingState ?? ''}, ${order.shippingZip ?? ''}, ${order.shippingCountry ?? ''}',
                        fontSize: sz(14, seprateTabletSize: 10),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 12.h),

              // Order summary
              Row(
                children: [
                  // Items count
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        size: sz(16, seprateTabletSize: 12).sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                      CustomText(
                        text:
                            '${AppLocalizations.of(context)!.items} ${order.items?.length ?? 0}',
                        fontSize: sz(14, seprateTabletSize: 10),
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                  SizedBox(width: 24.w),
                  // Distance
                  if (order.deliveryRoute?.totalDistance != null)
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: sz(16, seprateTabletSize: 12).sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4.w),
                        CustomText(
                          text:
                              '${order.deliveryRoute!.totalDistance!.toStringAsFixed(1)} km',
                          fontSize: sz(14, seprateTabletSize: 10),
                          color: Colors.grey[700],
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Earnings
              if (order.earnings?.total != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: AppLocalizations.of(context)!.earnings,
                      fontSize: sz(12, seprateTabletSize: 9),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    CustomText(
                      text: CurrencyFormatter.formatAmount(
                        context,
                        order.earnings!.total,
                      ),
                      fontSize: sz(18, seprateTabletSize: 14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusDisplayName(String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'assigned':
        return localizations.assigned;
      case 'in_progress':
        return localizations.inProgress;
      case 'completed':
        return localizations.delivered;
      case 'delivered':
        return localizations.delivered;
      case 'canceled':
        return localizations.canceled;
      default:
        return status;
    }
  }

  String _getLocalizedStatus(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'confirmed':
        return AppLocalizations.of(context)!.confirmed;
      case 'preparing':
        return AppLocalizations.of(context)!.preparing;
      case 'ready':
        return AppLocalizations.of(context)!.ready;
      case 'delivered':
        return AppLocalizations.of(context)!.delivered;
      case 'assigned':
        return AppLocalizations.of(context)!.assigned;
      case 'out_for_delivery':
        return AppLocalizations.of(context)!.outForDelivery;
      case 'canceled':
      case 'cancelled':
        return 'Canceled'; // Add this to localization if needed
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'canceled':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

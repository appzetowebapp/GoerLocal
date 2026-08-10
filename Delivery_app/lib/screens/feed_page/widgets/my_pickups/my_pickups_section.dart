// widgets/pickup_order/my_pickups_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/colors.dart';
import 'package:hyper_local/screens/feed_page/bloc/return_order/pickup_orders_list_bloc/pickup_order_list_bloc.dart';
import 'package:hyper_local/screens/feed_page/widgets/my_pickups/my_pickups_card.dart';
import 'package:hyper_local/utils/extensions.dart';
import 'package:lottie/lottie.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

import '../../../../config/helper.dart';
import '../../../../utils/widgets/custom_text.dart';
import '../../../../utils/widgets/loading_widget.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_bloc.dart';
import '../../bloc/deliveryboy_status_update_bloc/deliveryboy_status_event.dart';

class MyPickupsSection extends StatefulWidget {
  final bool isDeliveryBoyActive;

  const MyPickupsSection({super.key, required this.isDeliveryBoyActive});

  @override
  State<MyPickupsSection> createState() => _MyPickupsSectionState();
}

class _MyPickupsSectionState extends State<MyPickupsSection>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.isDeliveryBoyActive) {
      context.read<PickupOrderListBloc>().add(FetchPickupOrders());
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MyPickupsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDeliveryBoyActive) {
      context.read<PickupOrderListBloc>().add(
        FetchPickupOrders(forceRefresh: true),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PickupOrderListBloc>().add(LoadMorePickupOrders());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child:
          widget.isDeliveryBoyActive
              ? _buildActiveContent()
              : _buildInactiveWidget(),
    );
  }

  Widget _buildActiveContent() {
    return BlocConsumer<PickupOrderListBloc, PickupOrderListState>(
      listener: (context, state) {
        /*if (state is PickupOrderListError) {
          ToastManager.show(
            context: context,
            message: state.message,
            type: ToastType.error,
          );
        }*/
      },
      builder: (context, state) {
        if (state.status == ApiStatus.loading && state.orders.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (state.status == ApiStatus.success && state.orders.isEmpty) {
          return _buildEmptyState();
        }

        if (state.status == ApiStatus.success || state.isRefreshing) {
          final orders = state.orders;
          final hasReachedMax = state.hasReachedMax;
          final totalOrders = state.totalOrders;
          final isRefreshing = state.isRefreshing;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: AppLocalizations.of(context)!.pickupOrders,
                      fontSize: sz(20, seprateTabletSize: 18),
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text: AppLocalizations.of(
                        context,
                      )!.ordersCount(totalOrders.toString()),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async {
                        context.read<PickupOrderListBloc>().add(
                          FetchPickupOrders(forceRefresh: true),
                        );
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        itemCount: orders.length + (hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index >= orders.length) {
                            return const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: LoadingWidget(size: 50)),
                            );
                          }
                          return MyPickupsCard(
                            pickup: orders[index],
                          ).fadeAndSlideAnimation();
                        },
                      ),
                    ),
                    if (isRefreshing)
                      Align(
                        alignment: AlignmentGeometry.topCenter,
                        child: Container(
                          padding: EdgeInsets.all(8.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildInactiveWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRect(
            child: Align(
              alignment: Alignment.center,
              heightFactor: 0.7, // 👈 tweak this
              child: Lottie.asset(
                'assets/lottie/notactive.json',
                fit: BoxFit.contain,
              ),
            ),
          ),
          CustomText(
            text: AppLocalizations.of(context)!.accountInactive,
            fontSize: sz(22, seprateTabletSize: 20),
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
          CustomText(
            text:
                AppLocalizations.of(context)!.activateAccountToViewPickupOrders,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          ElevatedButton.icon(
            onPressed:
                () => context.read<DeliveryBoyStatusBloc>().add(
                  const ToggleStatus(true),
                ),
            icon: Icon(Icons.power_settings_new, size: 20.sp),
            label: CustomText(
              text: AppLocalizations.of(context)!.goOnline,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PickupOrderListBloc>().add(
          FetchPickupOrders(forceRefresh: true),
        );
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Lottie.asset(
                  'assets/lottie/NotDataFound.json',
                  width: 200.w,
                  height: 200.h,
                ),
                SizedBox(height: 24.h),
                CustomText(
                  text: AppLocalizations.of(context)!.noPickupOrders,
                  fontSize: sz(18),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

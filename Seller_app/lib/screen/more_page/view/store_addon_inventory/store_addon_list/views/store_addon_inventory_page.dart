import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_filter_sheet.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import '../../../../../../router/app_routes.dart';
import '../cubit/store_addon_inventory_cubit.dart';
import '../cubit/store_addon_inventory_state.dart';

class StoreAddonInventoryPage extends StatefulWidget {
  const StoreAddonInventoryPage({super.key});

  @override
  State<StoreAddonInventoryPage> createState() =>
      _StoreAddonInventoryPageState();
}

class _StoreAddonInventoryPageState extends State<StoreAddonInventoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<StoreAddonInventoryCubit>();
      cubit.reset();
      cubit.fetchInventory();
      cubit.fetchLookupData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<StoreAddonInventoryCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<StoreAddonInventoryCubit>().fetchInventory(
      isRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final l10n = AppLocalizations.of(context);

    return CustomScaffold(
      title: l10n?.storeAddonInventory ?? "Store Addon Inventory",
      showAppbar: true,
      centerTitle: true,
      showFilters: true,
      isHaveSearch: true,
      searchHint: l10n?.search ?? "Search",
      searchController: _searchController,
      filterType: FilterType.inventoryAddon,
      onSearchChanged: (query) {
        context.read<StoreAddonInventoryCubit>().searchInventory(query);
      },
      body: BlocListener<StoreAddonInventoryCubit, StoreAddonInventoryState>(
        listenWhen: (previous, current) =>
            previous.deleteStatus != current.deleteStatus,
        listener: (context, state) {
          if (state.deleteStatus == ApiStatus.success) {
            showCustomSnackbar(
              context: context,
              message:
                  state.deleteMessage ??
                  (l10n?.itemDeletedSuccess ?? "Item deleted successfully"),
            );
          } else if (state.deleteStatus == ApiStatus.failure) {
            showCustomSnackbar(
              context: context,
              message:
                  state.deleteMessage ??
                  (l10n?.itemDeleteFailed ?? "Failed to delete item"),
              isError: true,
            );
          }
        },
        child: BlocBuilder<StoreAddonInventoryCubit, StoreAddonInventoryState>(
          builder: (context, state) {
            final bool isLoadingEmpty =
                state.status == ApiStatus.loading && state.items.isEmpty;

            return Column(
              children: [
                // Header section for summary and Add button
                Padding(
                  padding: UIUtils.pagePadding(screenType),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isLoadingEmpty
                          ? CustomShimmer(
                              width: 150,
                              height: UIUtils.sectionTitle(screenType),
                            )
                          : Text(
                              "${l10n?.totalStoreAddon ?? "Total Store Addon"} (${state.total})",
                              style: TextStyle(
                                fontSize: UIUtils.tileTitle(screenType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      isLoadingEmpty
                          ? CustomShimmer(
                              width: 120,
                              height: 36,
                              borderRadius: BorderRadius.circular(
                                UIUtils.radiusMD(screenType),
                              ),
                            )
                          : SecondaryButton(
                              icon: Icons.add,
                              text: l10n?.add ?? 'Add',
                              onPressed: () async {
                                final cubit = context
                                    .read<StoreAddonInventoryCubit>();
                                await context.pushNamed(
                                  AppRoutes.createStoreAddonInventory,
                                );
                                cubit.fetchInventory(isRefresh: true);
                              },
                              height: 36,
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primaryColor,
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: UIUtils.cardsPadding(screenType),
                      itemCount: isLoadingEmpty
                          ? 10
                          : state.items.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isLoadingEmpty) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: UIUtils.gapMD(screenType),
                            ),
                            child: CardShimmer(
                              type: 'addons',
                              screenType: screenType,
                            ),
                          );
                        }

                        if (index >= state.items.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final item = state.items[index];

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: UIUtils.gapMD(screenType),
                          ),
                          child: CustomCard(
                            type: CardType.inventoryAddOn,
                            screenType: screenType,
                            data: {
                              'id': item.id,
                              'store_name': item.storeName,
                              'addon_item_title': item.addonItemTitle,
                              'addon_group_title': item.addonGroupTitle,
                              'price': item.price,
                              'cost': item.cost,
                              'stock': item.stock,
                              'is_available': item.isAvailable,
                            },
                            onEdit: () async {
                              final cubit = context
                                  .read<StoreAddonInventoryCubit>();
                              await context.pushNamed(
                                AppRoutes.createStoreAddonInventory,
                                extra: {'id': item.id},
                              );
                              cubit.fetchInventory(isRefresh: true);
                            },
                            onDelete: () {
                              if (!DemoGuard.shouldProceed(context)) return;

                              showAppAlertDialog(
                                context: context,
                                title:
                                    l10n?.deleteStoreAddonItem ??
                                    "Delete Store Addon Item",
                                message:
                                    l10n?.deleteStoreAddonItemConfirmation ??
                                    "Are you sure you want to delete this store addon item?",
                                confirmText: l10n?.yesDelete ?? "Yes, Delete",
                                cancelText: l10n?.cancel ?? "Cancel",
                                isDestructive: true,
                                onConfirm: () async {
                                  context
                                      .read<StoreAddonInventoryCubit>()
                                      .deleteInventoryItem(item.id);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

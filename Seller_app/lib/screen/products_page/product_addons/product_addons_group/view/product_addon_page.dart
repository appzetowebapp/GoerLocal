import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';

import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

import '../../../../../config/colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../service/api_base_helper.dart';
import '../../../../../service/demo_guard.dart';
import '../../../../../utils/image_path.dart';
import '../../../../../widgets/custom/card_shimmers.dart';
import '../../../../../widgets/custom/custom_alert_dialog.dart';
import '../../../../../widgets/custom/custom_card.dart';
import '../../../../../widgets/custom/custom_shimmer.dart';
import '../../../../../widgets/custom/custom_snackbar.dart';
import '../../../../../widgets/ui/empty_state_widget.dart';
import '../cubit/product_addon_cubit.dart';
import '../cubit/product_addon_state.dart';

class ProductAddonPage extends StatefulWidget {
  const ProductAddonPage({super.key});

  @override
  State<ProductAddonPage> createState() => _ProductAddonPageState();
}

class _ProductAddonPageState extends State<ProductAddonPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ProductAddonCubit>();
      cubit.clearSearch();
      cubit.fetchProductAddon();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductAddonCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<ProductAddonCubit>().fetchProductAddon(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final l10n = AppLocalizations.of(context);

    return CustomScaffold(
      title: l10n?.productAddOn ?? "Product Add On",
      showAppbar: true,
      centerTitle: true,
      isHaveSearch: true,
      searchHint: l10n?.search ?? "Search",
      searchController: _searchController,
      onSearchChanged: (query) {
        context.read<ProductAddonCubit>().searchProductAddon(query);
      },
      body: BlocConsumer<ProductAddonCubit, ProductAddonState>(
        listenWhen: (prev, curr) => prev.operationSuccess != curr.operationSuccess && curr.operationSuccess != null,
        listener: (context, state) {
          if (state.operationSuccess == true) {
            showCustomSnackbar(
              context: context,
              message:
                  state.operationMessage ?? l10n?.operationCompletedSuccessfully ?? "Operation completed successfully",
            );
          } else if (state.operationSuccess == false) {
            showCustomSnackbar(
              context: context,
              message: state.operationMessage ?? "Something went wrong. Please try again.",
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final bool isLoadingEmpty =
              state.fetchStatus == ApiStatus.initial ||
              (state.fetchStatus == ApiStatus.loading && state.productAddOns.isEmpty);

          if (!isLoadingEmpty && state.productAddOns.isEmpty) {
            return EmptyStateWidget(
              svgPath: ImagesPath.noProductFoundSvg,
              title: l10n?.noProductAddOnFound ?? "No Product Add on found",
              subtitle: l10n?.noProductAddOnFoundMessage ?? "You haven't added any product add on yet.",
              actionText: l10n?.addAddOns ?? "Add Add Ons",
              onAction: () async {
                final cubit = context.read<ProductAddonCubit>();
                await context.pushNamed(AppRoutes.createProductAddOn);
                cubit.fetchProductAddon(isRefresh: true);
              },
            );
          }

          return Column(
            children: [
              // Header section
              Padding(
                padding: UIUtils.pagePadding(screenType),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isLoadingEmpty
                        ? CustomShimmer(width: 150, height: UIUtils.sectionTitle(screenType))
                        : Text(
                            " ${l10n?.totalProductAddOn ?? "Total Product Add-on"} (${state.total})",
                            style: TextStyle(fontSize: UIUtils.tileTitle(screenType), fontWeight: FontWeight.w600),
                          ),

                    isLoadingEmpty
                        ? CustomShimmer(
                            width: 80,
                            height: 36,
                            borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
                          )
                        : SecondaryButton(
                            icon: Icons.add,
                            text: l10n?.add ?? 'Add',
                            onPressed: () async {
                              final cubit = context.read<ProductAddonCubit>();
                              await context.pushNamed(AppRoutes.createProductAddOn);
                              cubit.fetchProductAddon(isRefresh: true);
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
                        : state.productAddOns.length +
                              (state.hasMore ? (state.fetchStatus == ApiStatus.loadingMore ? 3 : 1) : 0),
                    itemBuilder: (context, index) {
                      if (isLoadingEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: UIUtils.gapMD(screenType)),
                          child: CardShimmer(type: 'addons', screenType: screenType),
                        );
                      }

                      if (index >= state.productAddOns.length) {
                        if (state.fetchStatus == ApiStatus.loadingMore) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: UIUtils.gapMD(screenType)),
                            child: CardShimmer(type: 'addons', screenType: screenType),
                          );
                        }
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
                        );
                      }

                      final addonGroup = state.productAddOns[index];

                      return Padding(
                        padding: EdgeInsets.only(bottom: UIUtils.gapMD(screenType)),
                        child: CustomCard(
                          type: CardType.productAddOn,
                          screenType: screenType,
                          data: {
                            'id': addonGroup.id,
                            'title': addonGroup.productTitle,
                            "variant": addonGroup.variantTitle,
                            "items_count": addonGroup.itemsCount,
                            "group_title": addonGroup.groupTitle,
                            "stores_count": addonGroup.storesCount,
                            'created_at': addonGroup.updatedAt,
                          },
                          onEdit: () async {
                            if (!DemoGuard.shouldProceed(context)) return;
                            final cubit = context.read<ProductAddonCubit>();
                            await context.pushNamed(AppRoutes.createProductAddOn, extra: {'model': addonGroup});
                            cubit.fetchProductAddon(isRefresh: true);
                          },
                          onDelete: () {
                            if (!DemoGuard.shouldProceed(context)) return;

                            showAppAlertDialog(
                              context: context,
                              title: l10n?.deleteProductAddOn ?? "Delete Product Add-on",
                              message:
                                  l10n?.deleteProductAddOnConfirmation ??
                                  "Are you sure you want to delete this product add-on?",
                              onConfirm: () {
                                context.read<ProductAddonCubit>().deleteProductAddon(
                                  variantId: addonGroup.productVariantId,
                                  groupId: addonGroup.addonGroupId,
                                );
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
    );
  }
}

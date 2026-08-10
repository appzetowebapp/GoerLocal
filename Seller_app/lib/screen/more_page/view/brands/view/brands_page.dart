import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/l10n/app_localizations.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/model/brands_model.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_shimmer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/widgets/add_brand_sheet.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
  final ScrollController _scrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    // Trigger initial load when entering the page
    context.read<BrandsBloc>().add(LoadBrandsInitial(search: null));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<BrandsBloc>().add(LoadMoreBrands());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;

        return CustomScaffold(
          centerTitle: true,
          showAppbar: true,
          isHaveSearch: true,

          onSearchChanged: (value) {
            _debouncer.run(() {
              context.read<BrandsBloc>().add(SearchBrands(value));
            });
          },
          title: l10n?.brands ?? "Brands",
          body: BlocListener<BrandsBloc, BrandsState>(
            listenWhen: (previous, current) =>
                previous.operationSuccess != current.operationSuccess &&
                current.operationSuccess != null,
            listener: (context, state) {
              if (state.operationSuccess == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.operationMessage ?? 'Success'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state.operationSuccess == false) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.operationMessage ?? 'Failed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: BlocBuilder<BrandsBloc, BrandsState>(
              builder: (context, state) {
                // Removed early return for initial loading to show shimmers in the layout

              if (state.error != null && state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title:
                      l10n?.somethingWentWrong ??
                      'Seems like there is some issue',
                  subtitle: l10n?.tryAgainLater ?? 'Please try again later',
                  actionText: l10n?.tryAgain ?? 'Try Again',
                  onAction: () {
                    context.read<BrandsBloc>().add(RefreshBrands());
                  },
                );
              }

              if (!state.isInitialLoading &&
                  !state.isRefreshing &&
                  state.items.isEmpty) {
                return EmptyStateWidget(
                  svgPath: ImagesPath.noProductFoundSvg,
                  title: l10n?.noBrandsFound ?? 'No brands found',
                  subtitle:
                      l10n?.noBrandsAddedYet ??
                      'You have not added any brands yet',
                  actionText: (l10n?.refresh ?? 'Refresh'),
                  onAction: () {
                    context.read<BrandsBloc>().add(RefreshBrands());
                  },
                );
              }

              final items = state.items;
              final hasMore = state.hasMore;
              final total = state.total ?? 0;
              final isPaginating = state.isPaginating;

              return Column(
                children: [
                  Padding(
                    padding: UIUtils.pagePadding(screenType),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        (state.isInitialLoading || state.isRefreshing) &&
                                state.items.isEmpty
                            ? CustomShimmer(
                                width: 150,
                                height: UIUtils.body(screenType),
                              )
                            : Text(
                                "${l10n?.total ?? "Total"} ${l10n?.brands ?? "Brands"} ($total)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: UIUtils.body(screenType),
                                ),
                              ),
                        Row(
                          children: [
                            if (state.isRefreshing)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: CustomLoadingIndicator(
                                  size: 16,
                                  strokeWidth: 2,
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => const AddBrandSheet(),
                                );
                              },
                              icon: const Icon(Icons.add, color: Colors.white, size: 16),
                              label: const Text(
                                "Add Brand",
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.authHeaderColor, // dark blue color
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primaryColor,
                      onRefresh: () async {
                        context.read<BrandsBloc>().add(RefreshBrands());
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: UIUtils.cardsPadding(screenType),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: UIUtils.gapMD(screenType)),
                        itemCount:
                            (state.isInitialLoading || state.isRefreshing) &&
                                state.items.isEmpty
                            ? 10
                            : items.length +
                                  (hasMore ? (isPaginating ? 10 : 1) : 0),
                        itemBuilder: (context, index) {
                          if ((state.isInitialLoading || state.isRefreshing) &&
                              state.items.isEmpty) {
                            return CardShimmer(
                              type: 'brand',
                              screenType: screenType,
                            );
                          }
                          if (index >= items.length) {
                            return CardShimmer(
                              type: 'brand',
                              screenType: screenType,
                            );
                          }

                          final brand = items[index];
                          return CustomCard(
                            type: CardType.brand,
                            data: _mapBrandToData(brand),
                            screenType: screenType,
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
      },
    );
  }

  Map<String, dynamic> _mapBrandToData(Brand brand) {
    return {
      "id": brand.id.toString(),
      "name": brand.title,
      "image": brand.logo,
      "status": brand.status,
      "category": brand.scopeCategoryTitle ?? 'N/A',
      "total_products": brand.totalProducts,
      "description": brand.description,
      "seller_id": brand.sellerId,
    };
  }
}

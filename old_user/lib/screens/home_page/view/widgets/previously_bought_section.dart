import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';
import '../../bloc/previously_bought/previously_bought_bloc.dart';
import '../../bloc/previously_bought/previously_bought_event.dart';
import '../../bloc/previously_bought/previously_bought_state.dart';
import 'package:animations/animations.dart';
import 'package:hyper_local/screens/product_detail_page/view/product_detail_page.dart';
import 'package:hyper_local/utils/widgets/custom_variant_selector_bottom_sheet.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import 'package:hyper_local/services/user_cart/cart_validation.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_event.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_local/model/user_cart_model/user_cart.dart';
import 'package:hyper_local/model/user_cart_model/cart_sync_action.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/product_listing_page/model/product_listing_type.dart';

class PreviouslyBoughtSection extends StatelessWidget {
  const PreviouslyBoughtSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviouslyBoughtBloc, PreviouslyBoughtState>(
      builder: (context, state) {
        if (state is PreviouslyBoughtLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: ShimmerWidget.rectangular(height: 20.h, width: 150.w, isBorder: false),
              ),
              SizedBox(
                height: 290.h,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: ShimmerWidget.rectangular(height: 290.h, width: 165.w, isBorder: true),
                  ),
                ),
              ),
            ],
          );
        } else if (state is PreviouslyBoughtLoaded) {
          if (state.products.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Products',
                      style: TextStyle(  
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF131124),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        GoRouter.of(context).push(
                          AppRoutes.productListing,
                          extra: {
                            'isTheirMoreCategory': false,
                            'title': 'New Products',
                            'logo': '',
                            'totalProduct': '',
                            'type': ProductListingType.previouslyBought,
                            'identifier': '',
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.purple, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 290.h,
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  scrollDirection: Axis.horizontal,
                  itemCount: state.products.length,
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return _ProductCard(product: product);
                  },
                ),
              ),
              SizedBox(height: 10.h),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductData product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final variant = product.variants.isNotEmpty ? product.variants[0] : null;
    final price = variant?.price ?? 0;
    final specialPrice = variant?.specialPrice ?? 0;
    final hasDiscount = specialPrice > 0 && specialPrice < price;

    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 500),
      transitionType: ContainerTransitionType.fade,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      openShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      closedColor: Colors.transparent,
      openColor: Colors.transparent,
      tappable: false,
      useRootNavigator: true,
      openBuilder: (context, _) => ProductDetailPage(
        productSlug: product.slug,
        initialData: ProductInitialData(
          title: product.title,
          mainImage: product.mainImage,
        ),
      ),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          width: 165.w,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
                    child: CachedNetworkImage(
                      imageUrl: product.mainImage,
                      height: 130.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Veg Indicator & Weight
                        Row(
                          children: [
                            Icon(Icons.circle, 
                              color: product.indicator == 'non_veg' ? Colors.red : Colors.green, 
                              size: 10),
                            SizedBox(width: 4.w),
                            Text(
                              '${variant?.weight ?? ""} ${variant?.sku.contains("g") == true ? "g" : "ml"}',
                              style: TextStyle(fontSize: 10.sp, color: Colors.black54),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        // Title
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF131124),
                          ),
                        ),
                        // Short Description
                        Text(
                          product.shortDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.sp, color: Colors.black54),
                        ),
                        SizedBox(height: 4.h),
                        // Rating
                        Row(
                          children: [
                            ...List.generate(5, (index) => Icon(
                              index < product.ratings.floor() ? Icons.star : Icons.star_border,
                              size: 12,
                              color: Colors.orange,
                            )),
                            SizedBox(width: 4.w),
                            Text(
                              '${product.ratings} (${product.ratingCount})',
                              style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        // Delivery Time
                        Row(
                          children: [
                            const Icon(TablerIcons.clock, size: 12, color: Colors.grey),
                            SizedBox(width: 2.w),
                            Text(
                              '${product.estimatedDeliveryTime} mins',
                              style: TextStyle(fontSize: 10.sp, color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Price & Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${hasDiscount ? specialPrice : price}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF131124),
                              ),
                            ),
                            BlocBuilder<CartBloc, CartState>(
                              builder: (context, cartState) {
                                final cartItem = _getCartItem(cartState, variant?.id ?? 0, variant?.storeId ?? 0);
                                final isInCart = cartItem != null;

                                if (isInCart) {
                                  return Container(
                                    height: 32.h,
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (cartItem.quantity > product.quantityStepSize) {
                                              context.read<CartBloc>().add(UpdateCartQty(
                                                cartKey: cartItem.cartKey,
                                                quantity: cartItem.quantity - product.quantityStepSize,
                                                cartItemId: cartItem.serverCartItemId,
                                                context: context,
                                              ));
                                            } else {
                                              context.read<CartBloc>().add(RemoveFromCart(
                                                cartKey: cartItem.cartKey,
                                                context: context,
                                              ));
                                            }
                                          },
                                          child: const Icon(Icons.remove, color: Colors.white, size: 16),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                                          child: Text(
                                            '${cartItem.quantity}',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final error = CartValidation.validateProductAddToCart(
                                              context: context,
                                              requestedQuantity: cartItem.quantity + product.quantityStepSize,
                                              minQty: product.minimumOrderQuantity,
                                              maxQty: product.totalAllowedQuantity,
                                              stock: variant?.stock ?? 0,
                                              isStoreOpen: true, // Assuming store is open
                                            );
                                            if (error == null) {
                                              context.read<CartBloc>().add(UpdateCartQty(
                                                cartKey: cartItem.cartKey,
                                                quantity: cartItem.quantity + product.quantityStepSize,
                                                cartItemId: cartItem.serverCartItemId,
                                                context: context,
                                              ));
                                            } else {
                                              ToastManager.show(context: context, message: error, type: ToastType.error);
                                            }
                                          },
                                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return GestureDetector(
                                  onTap: () {
                                    if (product.variants.length > 1) {
                                      showVariantBottomSheet(
                                        variantsList: product.variants,
                                        productData: product,
                                        productImage: product.mainImage,
                                        quantityStepSize: product.quantityStepSize,
                                        context: context,
                                      );
                                    } else if (variant != null) {
                                      final item = UserCart(
                                        productId: product.id.toString(),
                                        variantId: variant.id.toString(),
                                        variantName: variant.title,
                                        vendorId: variant.storeId.toString(),
                                        name: product.title,
                                        image: product.mainImage,
                                        price: hasDiscount ? specialPrice.toDouble() : price.toDouble(),
                                        originalPrice: price.toDouble(),
                                        quantity: product.quantityStepSize,
                                        minQty: product.minimumOrderQuantity,
                                        maxQty: product.totalAllowedQuantity,
                                        isOutOfStock: (variant.stock) <= 0,
                                        isSynced: false,
                                        updatedAt: DateTime.now(),
                                        syncAction: CartSyncAction.add,
                                      );
                                      context.read<CartBloc>().add(AddToCart(item: item, context: context));
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.purple.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  UserCart? _getCartItem(CartState state, int variantId, int storeId) {
    if (state is CartLoaded) {
      try {
        return state.items.firstWhere(
          (item) => int.tryParse(item.variantId) == variantId && int.tryParse(item.vendorId) == storeId,
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

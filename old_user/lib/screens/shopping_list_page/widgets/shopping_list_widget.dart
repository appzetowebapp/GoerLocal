import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/utils/widgets/custom_product_card.dart';

import '../../../bloc/user_cart_bloc/user_cart_bloc.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../model/user_cart_model/cart_sync_action.dart';
import '../../../model/user_cart_model/user_cart.dart';
import '../../../utils/widgets/custom_variant_selector_bottom_sheet.dart';

class ShoppingListWidget extends StatelessWidget {
  final List<ProductData> product;
  final String title;
  final int totalProducts;
  const ShoppingListWidget({
    super.key,
    required this.product,
    required this.title,
    required this.totalProducts
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 235.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              'Result for "$title"',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          SizedBox(height: 10.h,),
          SizedBox(
            height: 200.h,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 12.w),
              itemCount: totalProducts > 30 ? 30 : totalProducts,
              itemBuilder: (context, index) {
                final productData = product[index];
                final defaultVariant = productData.variants.firstWhere(
                      (v) => v.isDefault,
                  orElse: () {
                    if (productData.variants.isNotEmpty) return productData.variants.first;
                    throw Exception('No variants available for product ${productData.id}');
                  },
                );
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: SizedBox(
                    width: 140,
                    child: CustomProductCard(
                      productId: productData.id,
                      productImage: productData.mainImage,
                      productSlug: productData.slug,
                      productName: productData.title,
                      productPrice: defaultVariant.price.toString(),
                      specialPrice: defaultVariant.specialPrice.toString(),
                      productTags: [],
                      estimatedDeliveryTime: productData.estimatedDeliveryTime.toString(),
                      assetImage: '',
                      ratings: double.parse(productData.ratings.toString()),
                      ratingCount: productData.ratingCount,
                      onAddToCart: () {
                        if (productData.variants.length > 1) {
                          showVariantBottomSheet(
                            variantsList: productData.variants,
                            productData: productData,
                            productImage: productData.mainImage,
                            quantityStepSize: productData.quantityStepSize,
                            context: context,
                          );
                        } else {
                          final item = UserCart(
                              productId: productData.id.toString(),
                              variantId: defaultVariant.id.toString(),
                              variantName: defaultVariant.title.toString(),
                              vendorId: defaultVariant.storeId.toString(),
                              name: productData.title,
                              image: productData.mainImage,
                              price: defaultVariant.specialPrice.toDouble(),
                              originalPrice: defaultVariant.price.toDouble(),
                              quantity: productData.quantityStepSize,
                              serverCartItemId: null,
                              syncAction: CartSyncAction.add,
                              updatedAt: DateTime.now(),
                              minQty: productData.minimumOrderQuantity,
                              maxQty: productData.totalAllowedQuantity,
                              isOutOfStock: defaultVariant.stock <= 0,
                              isSynced: false
                          );

                          context.read<CartBloc>().add(AddToCart(item: item, context:  context));

                          /*context.read<AddToCartBloc>().add(
                            AddItemToCart(
                              productVariantId: productData.variants.first.id,
                              storeId: productData.variants.first.storeId,
                              quantity: productData.quantityStepSize,
                            ),
                          );*/
                        }
                      },
                      variantCount: productData.variants.length,
                      onVariantSelectorRequested: productData.variants.length > 1
                          ? () => showVariantBottomSheet(
                        variantsList: productData.variants,
                        productData: productData,
                        productImage: productData.mainImage,
                        quantityStepSize: productData.quantityStepSize,
                        context: context,
                      )
                          : null,
                      isStoreOpen: true,
                      isWishListed: productData.favorite.isNotEmpty,
                      productVariantId: defaultVariant.id,
                      storeId: defaultVariant.storeId,
                      wishlistItemId: productData.favorite.isNotEmpty ? productData.favorite.first.id ?? 0 : 0,
                      totalStocks: defaultVariant.stock,
                      imageFit: productData.imageFit,
                      quantityStepSize: productData.quantityStepSize,
                      minQty: productData.minimumOrderQuantity,
                      totalAllowedQuantity: productData.totalAllowedQuantity,
                    ),
                  ),
                );
              }
            ),
          )
        ],
      ),
    );
  }
}

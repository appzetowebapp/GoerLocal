import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/multi_selection_field.dart';
import 'package:hyper_local_seller/widgets/custom/custom_multi_selection_sheet.dart';

import '../../../../../service/api_base_helper.dart';
import '../../../../../widgets/custom/custom_snackbar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../cubit/create_product_addons_cubit.dart';
import '../cubit/create_product_addons_state.dart';
import '../models/lookup_models.dart';
import '../models/matrix_model.dart';
import '../../product_addons_group/model/product_addons_model.dart';

class CreateProductAddonsPage extends StatefulWidget {
  final ProductAddon? editModel;
  const CreateProductAddonsPage({super.key, this.editModel});

  @override
  State<CreateProductAddonsPage> createState() =>
      _CreateProductAddonsPageState();
}

class _CreateProductAddonsPageState extends State<CreateProductAddonsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.editModel != null) {
      context.read<CreateProductAddonsCubit>().initEdit(widget.editModel!);
    } else {
      // Initial fetch for lookups in Create mode
      context.read<CreateProductAddonsCubit>().searchProducts('');
      context.read<CreateProductAddonsCubit>().searchAddonGroups('');
    }
  }

  void _showProductSearch() {
    final cubit = context.read<CreateProductAddonsCubit>();
    cubit.searchProducts('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BlocBuilder<CreateProductAddonsCubit, CreateProductAddonsState>(
            bloc: cubit,
            builder: (context, state) {
              final items = [
                ...state.selectedProducts,
                ...state.products.where(
                  (p) => !state.selectedProducts.contains(p),
                ),
              ];
              return CustomMultiSelectionSheet<ProductLookup>(
                title: "Select Products",
                items: items
                    .map((p) => MultiSelectionItem(label: p.title, value: p))
                    .toList(),
                selectedValues: state.selectedProducts,
                isLoading: state.isProductsLoading,
                isLoadingMore: state.isProductsLoadingMore,
                onSearch: (q) => cubit.searchProducts(q),
                onLoadMore: () => cubit.loadMoreProducts(),
                onSelected: (selected) => cubit.selectProducts(selected),
              );
            },
          ),
    );
  }

  void _showVariantSearch(CreateProductAddonsState state) {
    if (state.selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select products first")),
      );
      return;
    }
    final cubit = context.read<CreateProductAddonsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BlocBuilder<CreateProductAddonsCubit, CreateProductAddonsState>(
            bloc: cubit,
            builder: (context, state) {
              final items = [
                ...state.selectedVariants,
                ...state.variants.where(
                  (v) => !state.selectedVariants.contains(v),
                ),
              ];
              return CustomMultiSelectionSheet<VariantLookup>(
                title: "Select Variants",
                items: items
                    .map(
                      (v) => MultiSelectionItem(
                        label: v.title,
                        value: v,
                        sublabel: v.product,
                      ),
                    )
                    .toList(),
                selectedValues: state.selectedVariants,
                isLoading: state.isVariantsLoading,
                onSelected: (selected) => cubit.selectVariants(selected),
              );
            },
          ),
    );
  }

  void _showAddonGroupSearch() {
    final cubit = context.read<CreateProductAddonsCubit>();
    cubit.searchAddonGroups('');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BlocBuilder<CreateProductAddonsCubit, CreateProductAddonsState>(
            bloc: cubit,
            builder: (context, state) {
              final items = [
                ...state.selectedAddonGroups,
                ...state.addonGroups.where(
                  (g) => !state.selectedAddonGroups.contains(g),
                ),
              ];
              return CustomMultiSelectionSheet<AddonGroupLookup>(
                title: "Select Add-on-Groups",
                items: items
                    .map((g) => MultiSelectionItem(label: g.title, value: g))
                    .toList(),
                selectedValues: state.selectedAddonGroups,
                isLoading: state.isAddonGroupsLoading,
                isLoadingMore: state.isAddonGroupsLoadingMore,
                onSearch: (q) => cubit.searchAddonGroups(q),
                onLoadMore: () => cubit.loadMoreAddonGroups(),
                onSelected: (selected) => cubit.selectAddonGroups(selected),
              );
            },
          ),
    );
  }

  void _validateAndSave(CreateProductAddonsState state) {
    final l10n = AppLocalizations.of(context);
    final isEdit = state.editModel != null;

    if (!isEdit) {
      if (state.selectedProducts.isEmpty) {
        showCustomSnackbar(
          context: context,
          message:
              l10n?.pleaseSelectProduct ?? "Please select at least one product",
          isError: true,
        );
        return;
      }
      if (state.selectedVariants.isEmpty) {
        showCustomSnackbar(
          context: context,
          message:
              l10n?.pleaseSelectVariant ?? "Please select at least one variant",
          isError: true,
        );
        return;
      }
      if (state.selectedAddonGroups.isEmpty) {
        showCustomSnackbar(
          context: context,
          message:
              l10n?.pleaseSelectAddonGroup ??
              "Please select at least one add-on group",
          isError: true,
        );
        return;
      }
    }

    if (state.matrices.isEmpty) {
      showCustomSnackbar(
        context: context,
        message:
            l10n?.noAttachmentsQueued ??
            "No attachments queued. Please check your selections.",
        isError: true,
      );
      return;
    }

    // Check if at least one item is selected across all matrices and stores
    bool hasAnySelection = false;
    for (var selection in state.selections.values) {
      if (selection.isNotEmpty) {
        hasAnySelection = true;
        break;
      }
    }

    if (!hasAnySelection) {
      showCustomSnackbar(
        context: context,
        message:
            l10n?.pleaseConfigureAtLeastOneItem ??
            "Please configure at least one item for at least one store",
        isError: true,
      );
      return;
    }

    context.read<CreateProductAddonsCubit>().saveAttachments();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final l10n = AppLocalizations.of(context);

    return CustomScaffold(
      showAppbar: true,
      centerTitle: true,
      title: context.read<CreateProductAddonsCubit>().state.editModel != null
          ? (l10n?.editAddonAttachment ?? "Edit add-on attachment")
          : (l10n?.attachAddonGroupToVariant ??
                "Attach add-on group to variant"),
      body: BlocListener<CreateProductAddonsCubit, CreateProductAddonsState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == ApiStatus.success &&
              state.matrices.isNotEmpty &&
              state.message != null) {
            showCustomSnackbar(context: context, message: state.message!);
            Navigator.pop(context);
          } else if (state.status == ApiStatus.failure) {
            showCustomSnackbar(
              context: context,
              message:
                  state.message ??
                  (l10n?.somethingWentWrong ?? "An error occurred"),
              isError: true,
            );
          }
        },
        child: BlocBuilder<CreateProductAddonsCubit, CreateProductAddonsState>(
          builder: (context, state) {
            final isEdit = state.editModel != null;
            final isInitialLoading =
                state.status == ApiStatus.loading && state.matrices.isEmpty;

            if (isInitialLoading) {
              return const Center(child: CustomLoadingIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isEdit) ...[
                          _buildEditHeader(state.editModel!, l10n),
                        ] else ...[
                          // Product Multi-Select
                          MultiSelectionField<ProductLookup>(
                            isRequired: true,
                            label: l10n?.products ?? "Products",
                            hint:
                                l10n?.searchProductsHint ?? "Search Products..",
                            selectedItems: state.selectedProducts,
                            itemLabel: (p) => p.title,
                            onTap: _showProductSearch,
                            onDeleted: (p) {
                              final newList = List<ProductLookup>.from(
                                state.selectedProducts,
                              )..remove(p);
                              context
                                  .read<CreateProductAddonsCubit>()
                                  .selectProducts(newList);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Variant Multi-Select
                          MultiSelectionField<VariantLookup>(
                            isRequired: true,
                            label: l10n?.variant ?? "Variant",
                            hint:
                                l10n?.searchVariantsHint ?? "Search Variants..",
                            selectedItems: state.selectedVariants,
                            itemLabel: (v) => v.title,
                            onTap: () => _showVariantSearch(state),
                            onDeleted: (v) {
                              final newList = List<VariantLookup>.from(
                                state.selectedVariants,
                              )..remove(v);
                              context
                                  .read<CreateProductAddonsCubit>()
                                  .selectVariants(newList);
                            },
                          ),
                          const SizedBox(height: 20),

                          // Add-on-Groups Multi-Select
                          MultiSelectionField<AddonGroupLookup>(
                            isRequired: true,
                            label: l10n?.addonGroup ?? "Add-on Group",
                            hint:
                                l10n?.searchAddonGroupsHint ??
                                "Search Add-on Groups..",
                            selectedItems: state.selectedAddonGroups,
                            itemLabel: (g) => g.title,
                            onTap: _showAddonGroupSearch,
                            onDeleted: (g) {
                              final newList = List<AddonGroupLookup>.from(
                                state.selectedAddonGroups,
                              )..remove(g);
                              context
                                  .read<CreateProductAddonsCubit>()
                                  .selectAddonGroups(newList);
                            },
                          ),
                        ],

                        const SizedBox(height: 30),

                        // Matrices section
                        if (state.status == ApiStatus.loading)
                          const Center(child: CustomLoadingIndicator())
                        else if (state.matrices.isNotEmpty) ...[
                          Text(
                            "${state.matrices.length} attachments queued",
                            style: TextStyle(
                              fontSize: UIUtils.tileTitle(screenType),
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...state.matrices.map(
                            (matrix) => _buildMatrixPair(matrix, state, l10n),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
                  child: PrimaryButton(
                    text: isEdit
                        ? (l10n?.updateAttachment ?? "Update Attachment")
                        : (l10n?.saveAttachment ?? "Save Attachment"),
                    isLoading: state.status == ApiStatus.loading,
                    onPressed: () => _validateAndSave(state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditHeader(ProductAddon model, AppLocalizations? l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryColor.withOpacity(0.1)
            : AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n?.product ?? "Product", model.productTitle),
          const SizedBox(height: 12),
          _buildInfoRow(l10n?.variant ?? "Variant", model.variantTitle),
          const SizedBox(height: 12),
          _buildInfoRow(l10n?.addonGroup ?? "Add-on Group", model.groupTitle),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixPair(
    AddonMatrix matrix,
    CreateProductAddonsState state,
    AppLocalizations? l10n,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: colorScheme.onSurface,
        collapsedIconColor: isDark
            ? colorScheme.onSurfaceVariant
            : Colors.grey.shade400,
        title: Text(
          "${matrix.variant.title} x ${matrix.group.title}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        children: [
          Divider(color: colorScheme.outlineVariant, height: 1),
          ...matrix.stores.asMap().entries.map((entry) {
            final index = entry.key;
            final store = entry.value;
            return Column(
              children: [
                _buildStoreRow(matrix, store, state, l10n),
                if (index < matrix.stores.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStoreRow(
    AddonMatrix matrix,
    MatrixIdTitle store,
    CreateProductAddonsState state,
    AppLocalizations? l10n,
  ) {
    final selectionKey = "${matrix.pairKey}_${store.id}";
    final selectedItems = state.selections[selectionKey] ?? [];
    final isStoreEnabled = selectedItems.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHigh
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              iconColor: colorScheme.onSurface,
              collapsedIconColor: isDark
                  ? colorScheme.onSurfaceVariant
                  : Colors.grey.shade400,
              leading: _buildCustomSwitch(
                value: isStoreEnabled,
                onChanged: (val) {
                  context.read<CreateProductAddonsCubit>().toggleStoreSelection(
                    matrix,
                    store.id,
                    val,
                  );
                },
              ),
              title: Text(
                store.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                isStoreEnabled
                    ? "${selectedItems.length} Item configured"
                    : "Not applied",
                style: TextStyle(
                  color: isStoreEnabled ? AppColors.primaryColor : Colors.grey,
                  fontSize: 12,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      ...matrix.items.map((item) {
                        final isSelected = selectedItems.contains(item.id);
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainer
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            leading: _buildCustomSwitch(
                              value: isSelected,
                              onChanged: (val) {
                                context
                                    .read<CreateProductAddonsCubit>()
                                    .toggleItemSelection(selectionKey, item.id);
                              },
                            ),
                            title: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            subtitle: (() {
                              final inv = (matrix.inventory)
                                  .where(
                                    (i) =>
                                        i.storeId == store.id &&
                                        i.addonItemId == item.id,
                                  )
                                  .firstOrNull;
                              final stockText = inv != null
                                  ? " • ${l10n?.stock ?? "Stock"}: ${inv.stock}"
                                  : "";
                              return Text(
                                "${l10n?.price ?? "Price"}: ${item.price}$stockText",
                                style: TextStyle(
                                  color: isDark
                                      ? colorScheme.onSurfaceVariant
                                      : Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              );
                            })(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12), // Better separation between stores
        ],
      ),
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.primaryColor,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      trackOutlineWidth: WidgetStateProperty.all(0),
    );
  }
}

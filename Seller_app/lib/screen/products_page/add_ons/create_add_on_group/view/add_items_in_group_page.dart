import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../../../../../config/colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../service/api_base_helper.dart';
import '../cubit/create_addon_group_cubit.dart';
import '../cubit/create_addon_group_state.dart';
import '../ui_models/UI_Models.dart';
import '../widgets/create_add_group_item_card.dart';

class AddItemsInGroupPage extends StatefulWidget {
  const AddItemsInGroupPage({super.key, required this.pageIndex});
  final int pageIndex;
  @override
  State<AddItemsInGroupPage> createState() => _AddItemsInGroupPageState();
}

class _AddItemsInGroupPageState extends State<AddItemsInGroupPage> {
  final List<AddonItemController> _itemControllers = [];

  @override
  void initState() {
    super.initState();
    final initialItems = context.read<CreateAddonGroupCubit>().state.data.items;
    if (initialItems.isNotEmpty) {
      for (var item in initialItems) {
        _itemControllers.add(_createController(item));
      }
    } else {
      _addNewItem();
    }
  }

  /// Explanation: This function converts a static data model (AddonItemFormData)
  /// into an interactive UI controller (AddonItemController). It populates
  /// all TextEditingControllers with existing data, allowing the UI to
  /// pre-fill fields during edit or creation.
  AddonItemController _createController(AddonItemFormData item) {
    return AddonItemController(
      id: item.id,
      indicator: item.indicator,
      status: item.status,
      isAvailable: item.isAvailable,
      initialTitle: item.title,
      initialPrice: item.price > 0 ? item.price.toString() : '',
      initialCost: item.cost != null ? item.cost.toString() : '',
      initialSortOrder: item.sortOrder.toString(),
    );
  }

  void _addNewItem() {
    setState(() {
      _itemControllers.add(_createController(const AddonItemFormData()));
    });
    _updateBloc();
  }

  void _removeItem(int index) {
    setState(() {
      _itemControllers[index].dispose();
      _itemControllers.removeAt(index);
    });
    _updateBloc();
  }

  void _updateBloc() {
    final cubit = context.read<CreateAddonGroupCubit>();
    final items = _itemControllers.map((c) {
      return AddonItemFormData(
        id: c.id,
        title: c.titleController.text,
        price: double.tryParse(c.priceController.text) ?? 0.0,
        cost: double.tryParse(c.costController.text),
        indicator: c.indicator,
        status: c.status,
        isAvailable: c.isAvailable,
        sortOrder: int.tryParse(c.sortOrderController.text) ?? 0,
      );
    }).toList();

    cubit.updateData(cubit.state.data.copyWith(items: items));
  }

  @override
  void dispose() {
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validateAndSubmit(BuildContext context) {
    final cubit = context.read<CreateAddonGroupCubit>();
    final l10n = AppLocalizations.of(context);

    if (_itemControllers.isEmpty) {
      showCustomSnackbar(
        context: context,
        message: l10n?.addAtLeastOneVariant ?? "Please add at least one item",
        isError: true,
      );
      return;
    }

    for (int i = 0; i < _itemControllers.length; i++) {
      final controller = _itemControllers[i];
      if (controller.titleController.text.trim().isEmpty) {
        showCustomSnackbar(
          context: context,
          message: "${l10n?.pleaseEnterItemDetails ?? "Please enter details for item"} #${i + 1}",
          isError: true,
        );
        return;
      }
      if (controller.priceController.text.trim().isEmpty) {
        showCustomSnackbar(
          context: context,
          message: "${l10n?.pleaseEnterItemDetails ?? "Please enter details for item"} #${i + 1}",
          isError: true,
        );
        return;
      }
      final price = double.tryParse(controller.priceController.text);
      if (price == null || price < 0) {
        showCustomSnackbar(
          context: context,
          message: "${l10n?.pleaseEnterItemDetails ?? "Please enter details for item"} #${i + 1}",
          isError: true,
        );
        return;
      }
    }

    cubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final l10n = AppLocalizations.of(context);

    return BlocListener<CreateAddonGroupCubit, CreateAddonGroupState>(
      listener: (context, state) {
        if (state.status == ApiStatus.success) {
          showCustomSnackbar(context: context, message: state.message ?? "Success");
          context.pop();
        } else if (state.status == ApiStatus.failure) {
          showCustomSnackbar(context: context, message: state.message ?? "Error", isError: true);
          context.read<CreateAddonGroupCubit>().resetStatus();
        }
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
              itemCount: _itemControllers.length + 1,
              itemBuilder: (context, index) {
                if (index == _itemControllers.length) {
                  return Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(AppLocalizations.of(context)!.addField),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  );
                }

                return AddOnsItemCard(
                  index: index,
                  controller: _itemControllers[index],
                  screenType: screenType,
                  onDelete: () => _removeItem(index),
                  onChanged: _updateBloc,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
            child: BlocBuilder<CreateAddonGroupCubit, CreateAddonGroupState>(
              builder: (context, state) {
                return PrimaryButton(
                  isLoading: state.status == ApiStatus.loading,
                  text: state.data.id == null
                      ? (l10n?.saveAddonGroup ?? "Save Add-on-Group")
                      : (l10n?.updateAddonGroup ?? "Update Add-on-Group"),
                  onPressed: () => state.status == ApiStatus.loading ? null : _validateAndSubmit(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddonItemController {
  final int? id;
  final TextEditingController titleController;
  final TextEditingController priceController;
  final TextEditingController costController;
  final TextEditingController sortOrderController;
  String? indicator;
  String status;
  bool isAvailable;

  AddonItemController({
    this.id,
    this.indicator,
    this.status = 'active',
    this.isAvailable = true,
    String initialTitle = '',
    String initialPrice = '',
    String initialCost = '',
    String initialSortOrder = '0',
  }) : titleController = TextEditingController(text: initialTitle),
       priceController = TextEditingController(text: initialPrice),
       costController = TextEditingController(text: initialCost),
       sortOrderController = TextEditingController(text: initialSortOrder);

  void dispose() {
    titleController.dispose();
    priceController.dispose();
    costController.dispose();
    sortOrderController.dispose();
  }
}

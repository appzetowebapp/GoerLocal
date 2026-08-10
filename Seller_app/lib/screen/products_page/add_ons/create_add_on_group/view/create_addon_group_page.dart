import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_dropdown.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../../../../../config/colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../addon_groups/model/addon_group_model.dart';
import '../../addon_groups/repo/addon_groups_repo.dart';
import '../cubit/create_addon_group_cubit.dart';
import '../cubit/create_addon_group_state.dart';
import 'add_items_in_group_page.dart';

class CreateAddonGroupPage extends StatelessWidget {
  final AddonGroup? addonGroup;
  const CreateAddonGroupPage({super.key, this.addonGroup});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateAddonGroupCubit(context.read<AddonGroupsRepo>())..initForEdit(addonGroup),
      child: _CreateAddonGroupView(isEdit: addonGroup != null),
    );
  }
}

class _CreateAddonGroupView extends StatefulWidget {
  final bool isEdit;
  const _CreateAddonGroupView({required this.isEdit});

  @override
  State<_CreateAddonGroupView> createState() => _CreateAddonGroupViewState();
}

class _CreateAddonGroupViewState extends State<_CreateAddonGroupView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();
  String _status = 'active';
  String _selectionType = 'single';
  bool _isRequired = false;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    final data = context.read<CreateAddonGroupCubit>().state.data;
    _titleController.text = data.title;
    _sortOrderController.text = data.sortOrder.toString();
    _status = data.status;
    _selectionType = data.selectionType;
    _isRequired = data.isRequired;
  }

  void _updateBloc() {
    final cubit = context.read<CreateAddonGroupCubit>();
    final currentData = cubit.state.data;
    cubit.updateData(
      currentData.copyWith(
        title: _titleController.text,
        sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
        status: _status,
        selectionType: _selectionType,
        isRequired: _isRequired,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;

    final l10n = AppLocalizations.of(context);
    return CustomScaffold(
      title: pageIndex == 0
          ? (widget.isEdit
                ? (l10n?.editAddonGroup ?? "Edit Add-on Group")
                : (l10n?.createAddonGroup ?? "Create Add-on Group"))
          : (l10n?.addItemsInThisGroup ?? "Add Item in this Group"),
      showAppbar: true,
      centerTitle: true,
      onBackTap: () {
        if (pageIndex == 1) {
          setState(() {
            pageIndex = 0;
          });
        } else {
          context.pop();
        }
      },
      body: IndexedStack(
        index: pageIndex,
        children: [
          BlocBuilder<CreateAddonGroupCubit, CreateAddonGroupState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            label: l10n?.groupTitle ?? "Group Title",
                            hint: l10n?.enterGroupTitle ?? "Enter group title",
                            isRequired: true,
                            controller: _titleController,
                            onChanged: (v) => _updateBloc(),
                          ),
                          const SizedBox(height: 20),
                          CustomDropdown<String>(
                            label: l10n?.status ?? "Status",
                            isRequired: true,
                            value: _status,
                            items: [
                              CustomDropdownItem(label: l10n?.active ?? "Active", value: "active"),
                              CustomDropdownItem(label: l10n?.inactive ?? "Inactive", value: "inactive"),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _status = val);
                                _updateBloc();
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomDropdown<String>(
                            label: l10n?.selectionType ?? "Selection Type",
                            isRequired: true,
                            value: _selectionType,
                            items: [
                              CustomDropdownItem(
                                label: l10n?.singleRadioPickOne ?? "Single (Radio - Pick one)",
                                value: "single",
                              ),
                              CustomDropdownItem(
                                label: l10n?.multipleCheckboxPickMultiple ?? "Multiple (Checkbox - Pick multiple)",
                                value: "multiple",
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectionType = val);
                                _updateBloc();
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.isRequiredLabel ?? "Required",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n?.requiredDescription ??
                                          "Customer must pick at least one option from this Group",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isRequired,
                                onChanged: (val) {
                                  setState(() => _isRequired = val);
                                  _updateBloc();
                                },
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.primaryColor,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: Colors.grey.shade300,
                                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                                trackOutlineWidth: WidgetStateProperty.all(0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            onChanged: (v) => _updateBloc(),
                            label: l10n?.sortOrder ?? "Sort Order",
                            hint: "0",
                            controller: _sortOrderController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(UIUtils.gapMD(screenType)),
                    child: PrimaryButton(
                      text: l10n?.addItemsButton ?? "Add Items",
                      onPressed: () {
                        if (_titleController.text.trim().isEmpty) {
                          showCustomSnackbar(
                            context: context,
                            message: l10n?.pleaseEnterGroupTitle ?? "Please enter group title",
                            isError: true,
                          );
                          return;
                        }
                        setState(() {
                          pageIndex = 1;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          AddItemsInGroupPage(pageIndex: pageIndex),
        ],
      ),
    );
  }
}

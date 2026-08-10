import 'package:flutter/material.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';

class MultiSelectionItem<T> {
  final String label;
  final T value;
  final String? sublabel;

  MultiSelectionItem({required this.label, required this.value, this.sublabel});
}

class CustomMultiSelectionSheet<T> extends StatefulWidget {
  final String title;
  final List<MultiSelectionItem<T>> items;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onSelected;
  final Function(String)? onSearch;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool isLoadingMore;

  const CustomMultiSelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedValues,
    required this.onSelected,
    this.onSearch,
    this.onLoadMore,
    this.isLoading = false,
    this.isLoadingMore = false,
  });

  @override
  State<CustomMultiSelectionSheet<T>> createState() =>
      _CustomMultiSelectionSheetState<T>();

  static void show<T>({
    required BuildContext context,
    required String title,
    required List<MultiSelectionItem<T>> items,
    required List<T> selectedValues,
    required ValueChanged<List<T>> onSelected,
    Function(String)? onSearch,
    VoidCallback? onLoadMore,
    bool isLoading = false,
    bool isLoadingMore = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomMultiSelectionSheet<T>(
        title: title,
        items: items,
        selectedValues: selectedValues,
        onSelected: onSelected,
        onSearch: onSearch,
        onLoadMore: onLoadMore,
        isLoading: isLoading,
        isLoadingMore: isLoadingMore,
      ),
    );
  }
}

class _CustomMultiSelectionSheetState<T>
    extends State<CustomMultiSelectionSheet<T>> {
  late List<T> _tempSelectedValues;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelectedValues = List.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      if (widget.onSearch != null) {
        widget.onSearch!(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(UIUtils.radiusLG(screenType)),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: UIUtils.pageTitle(screenType),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.onSelected(_tempSelectedValues);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onSearch != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomTextField(
                    controller: _searchController,
                    hint: "Search...",
                    onChanged: _onSearchChanged,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              const Divider(),
              Expanded(
                child: widget.isLoading
                    ? const Center(child: CustomLoadingIndicator())
                    : widget.items.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No results found",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200 &&
                              !widget.isLoading &&
                              !widget.isLoadingMore &&
                              widget.onLoadMore != null) {
                            widget.onLoadMore!();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount:
                              widget.items.length +
                              (widget.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == widget.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CustomLoadingIndicator()),
                              );
                            }
                            final item = widget.items[index];
                            final isSelected = _tempSelectedValues.contains(
                              item.value,
                            );

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _tempSelectedValues.remove(item.value);
                                  } else {
                                    _tempSelectedValues.add(item.value);
                                  }
                                });
                              },
                              child: Container(
                                color: isSelected
                                    ? AppColors.primaryColor.withValues(
                                        alpha: 0.05,
                                      )
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.label,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primaryColor
                                                  : null,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : null,
                                            ),
                                          ),
                                          if (item.sublabel != null)
                                            Text(
                                              item.sublabel!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? AppColors.primaryColor
                                                          .withValues(
                                                            alpha: 0.7,
                                                          )
                                                    : Colors.grey,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primaryColor,
                                      )
                                    else
                                      Icon(
                                        Icons.circle_outlined,
                                        color: Colors.grey.shade300,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

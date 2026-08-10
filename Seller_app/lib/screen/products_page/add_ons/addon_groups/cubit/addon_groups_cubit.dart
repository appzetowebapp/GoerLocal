import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hyper_local_seller/utils/debouncer.dart';

import '../../../../../service/api_base_helper.dart';
import '../model/addon_group_model.dart';
import '../repo/addon_groups_repo.dart';
import 'addon_groups_state.dart';

class AddonGroupsCubit extends Cubit<AddonGroupsState> {
  final AddonGroupsRepo _repo;
  String? _searchQuery;
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  AddonGroupsCubit(this._repo) : super(const AddonGroupsState()) {
    print("AddonGroupsCubit: Constructor called. Fetching addon groups...");
    fetchAddonGroups();
  }

  Future<void> fetchAddonGroups({bool isRefresh = false}) async {
    print("AddonGroupsCubit: fetchAddonGroups started (isRefresh: $isRefresh)");
    if (isRefresh) {
      emit(state.copyWith(fetchStatus: ApiStatus.initial));
    }

    emit(state.copyWith(fetchStatus: ApiStatus.loading));

    try {
      final response = await _repo.getAddonGroups(page: 1, search: _searchQuery);

      final result = AddonGroupResponse.fromJson(response);
      final data = result.data;

      if (result.success && data != null) {
        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            addonGroups: data.data,
            currentPage: data.currentPage,
            lastPage: data.lastPage,
            total: data.total,
            hasMore: data.currentPage < data.lastPage,
          ),
        );
      } else {
        emit(state.copyWith(fetchStatus: ApiStatus.failure, message: result.message));
      }
    } catch (e, stacktrace) {
      emit(state.copyWith(fetchStatus: ApiStatus.failure, message: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state.fetchStatus == ApiStatus.loadingMore || !state.hasMore) return;

    emit(state.copyWith(fetchStatus: ApiStatus.loadingMore));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _repo.getAddonGroups(page: nextPage, search: _searchQuery);

      final result = AddonGroupResponse.fromJson(response);
      final data = result.data;

      if (result.success && data != null) {
        final updatedList = List<AddonGroup>.from(state.addonGroups)..addAll(data.data);

        emit(
          state.copyWith(
            fetchStatus: ApiStatus.success,
            addonGroups: updatedList,
            currentPage: data.currentPage,
            lastPage: data.lastPage,
            total: data.total,
            hasMore: data.currentPage < data.lastPage,
          ),
        );
      } else {
        emit(state.copyWith(fetchStatus: ApiStatus.success, message: result.message));
      }
    } catch (e, stacktrace) {
      emit(state.copyWith(fetchStatus: ApiStatus.success, message: e.toString()));
    }
  }

  void searchAddonGroups(String query) {
    _searchQuery = query.isEmpty ? null : query;
    _debouncer.run(() {
      fetchAddonGroups(isRefresh: true);
    });
  }

  void clearSearch() {
    _searchQuery = null;
    emit(state.copyWith(fetchStatus: ApiStatus.initial, addonGroups: []));
  }

  void resetOperationStatus() {
    emit(state.copyWith(operationSuccess: null, operationMessage: null));
  }

  Future<void> deleteAddonGroup(int id) async {
    emit(state.copyWith(operationSuccess: null, operationMessage: null));
    try {
      final response = await _repo.deleteAddonGroup(id);
      if (response['success'] == true) {
        emit(
          state.copyWith(
            operationSuccess: true,
            operationMessage: response['message'] ?? "Add-on group deleted successfully",
          ),
        );
        fetchAddonGroups(isRefresh: true);
      } else {
        emit(
          state.copyWith(
            operationSuccess: false,
            operationMessage: response['message'] ?? "Failed to delete add-on group",
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(operationSuccess: false, operationMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debouncer.dispose();
    return super.close();
  }
}

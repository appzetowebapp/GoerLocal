import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../service/api_base_helper.dart';
import '../../addon_groups/model/addon_group_model.dart';
import '../../addon_groups/repo/addon_groups_repo.dart';
import '../ui_models/UI_Models.dart';
import 'create_addon_group_state.dart';

class CreateAddonGroupCubit extends Cubit<CreateAddonGroupState> {
  final AddonGroupsRepo _repo;

  CreateAddonGroupCubit(this._repo) : super(const CreateAddonGroupState());

  void initForEdit(AddonGroup? model) {

    //if(model == null {CreateAddonGroupState()}
    if (model != null) {

      final formData = AddonGroupFormData.fromJson(model.toJson());
      emit(state.copyWith(data: formData, status: ApiStatus.initial));
    }
  }

  void updateData(AddonGroupFormData data) {
    emit(state.copyWith(data: data, status: ApiStatus.initial));
  }

  Future<void> submit() async {
    emit(state.copyWith(status: ApiStatus.loading, clearMessage: true));

    try {
      final id = state.data.id;
      final response = id != null
          ? await _repo.updateAddonGroup(id, state.data.toJson())
          : await _repo.createAddonGroup(state.data.toJson());

      if (response['success'] == true) {
        emit(
          state.copyWith(status: ApiStatus.success, message: response['message'] ?? "Add-on group saved successfully"),
        );
      } else {
        emit(state.copyWith(status: ApiStatus.failure, message: response['message'] ?? "Failed to save add-on group"));
      }
    } catch (e) {
      emit(state.copyWith(status: ApiStatus.failure, message: e.toString()));
    }
  }

  void resetStatus() {
    emit(state.copyWith(status: ApiStatus.initial, clearMessage: true));
  }
}

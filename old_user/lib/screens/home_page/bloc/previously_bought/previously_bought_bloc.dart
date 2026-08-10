import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repo/previously_bought_repository.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'previously_bought_event.dart';
import 'previously_bought_state.dart';

class PreviouslyBoughtBloc extends Bloc<PreviouslyBoughtEvent, PreviouslyBoughtState> {
  final PreviouslyBoughtRepository repository = PreviouslyBoughtRepository();

  PreviouslyBoughtBloc() : super(PreviouslyBoughtInitial()) {
    on<FetchPreviouslyBoughtProducts>(_onFetchPreviouslyBoughtProducts);
  }

  Future<void> _onFetchPreviouslyBoughtProducts(
      FetchPreviouslyBoughtProducts event, Emitter<PreviouslyBoughtState> emit) async {
    emit(PreviouslyBoughtLoading());
    try {
      final response = await repository.fetchPreviouslyBoughtProducts();
      if (response['success'] == true) {
        try {
          final productsList = List<ProductData>.from(
              response['data']['data'].map((data) {
                try {
                  return ProductData.fromJson(data);
                } catch (e) {
                  return null;
                }
              }).where((element) => element != null));
          
          emit(PreviouslyBoughtLoaded(
            products: productsList,
            message: response['message'],
          ));
        } catch (e) {
          emit(PreviouslyBoughtFailed(error: 'Failed to process products: $e'));
        }
      } else {
        emit(PreviouslyBoughtFailed(error: response['message']));
      }
    } catch (e) {
      emit(PreviouslyBoughtFailed(error: e.toString()));
    }
  }
}

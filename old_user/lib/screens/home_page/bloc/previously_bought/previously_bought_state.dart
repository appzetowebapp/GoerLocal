import 'package:equatable/equatable.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';

abstract class PreviouslyBoughtState extends Equatable {
  const PreviouslyBoughtState();

  @override
  List<Object?> get props => [];
}

class PreviouslyBoughtInitial extends PreviouslyBoughtState {}

class PreviouslyBoughtLoading extends PreviouslyBoughtState {}

class PreviouslyBoughtLoaded extends PreviouslyBoughtState {
  final List<ProductData> products;
  final String message;

  const PreviouslyBoughtLoaded({required this.products, required this.message});

  @override
  List<Object?> get props => [products, message];
}

class PreviouslyBoughtFailed extends PreviouslyBoughtState {
  final String error;

  const PreviouslyBoughtFailed({required this.error});

  @override
  List<Object?> get props => [error];
}

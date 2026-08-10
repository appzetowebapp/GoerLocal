import 'package:equatable/equatable.dart';

abstract class PreviouslyBoughtEvent extends Equatable {
  const PreviouslyBoughtEvent();

  @override
  List<Object?> get props => [];
}

class FetchPreviouslyBoughtProducts extends PreviouslyBoughtEvent {}

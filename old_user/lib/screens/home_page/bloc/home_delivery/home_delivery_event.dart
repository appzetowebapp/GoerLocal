import 'package:equatable/equatable.dart';

abstract class HomeDeliveryEvent extends Equatable {
  const HomeDeliveryEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeDeliveryData extends HomeDeliveryEvent {
  final double latitude;
  final double longitude;
  final String? token;
  final int? addressId;
  final String addressLabel; // e.g. "South Tukoganj"

  const FetchHomeDeliveryData({
    required this.latitude,
    required this.longitude,
    this.token,
    this.addressId,
    required this.addressLabel,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        token,
        addressId,
        addressLabel,
      ];
}

import 'package:equatable/equatable.dart';

abstract class HomeDeliveryState extends Equatable {
  const HomeDeliveryState();

  @override
  List<Object?> get props => [];
}

class HomeDeliveryInitial extends HomeDeliveryState {}

class HomeDeliveryLoading extends HomeDeliveryState {}

class HomeDeliveryLoaded extends HomeDeliveryState {
  final int zoneId;
  final String nearestStoreName;
  final double distanceKm;
  final int estimatedMinutes;
  final String addressLabel; // Added this to pass the formatted label to UI

  const HomeDeliveryLoaded({
    required this.zoneId,
    required this.nearestStoreName,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.addressLabel,
  });

  @override
  List<Object?> get props => [
        zoneId,
        nearestStoreName,
        distanceKm,
        estimatedMinutes,
        addressLabel,
      ];
}

class HomeDeliveryError extends HomeDeliveryState {
  final String message;

  const HomeDeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}

class HomeDeliveryNotAvailable extends HomeDeliveryState {
  const HomeDeliveryNotAvailable();
}

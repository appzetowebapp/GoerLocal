import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/constant.dart';

import 'home_delivery_event.dart';
import 'home_delivery_state.dart';

class HomeDeliveryBloc extends Bloc<HomeDeliveryEvent, HomeDeliveryState> {
  HomeDeliveryBloc() : super(HomeDeliveryInitial()) {
    on<FetchHomeDeliveryData>(_onFetchHomeDeliveryData);
  }

  Future<void> _onFetchHomeDeliveryData(
      FetchHomeDeliveryData event, Emitter<HomeDeliveryState> emit) async {
    emit(HomeDeliveryLoading());

    try {
      // 1) Zone check
      final zoneUri = Uri.parse(
          '${AppConstant.baseUrl}delivery-zone/check?latitude=${event.latitude}&longitude=${event.longitude}');
      final zoneRes = await http.get(zoneUri, headers: {'Accept': 'application/json'});
      if (zoneRes.statusCode != 200) {
        emit(const HomeDeliveryNotAvailable());
        return;
      }
      final zoneData = json.decode(zoneRes.body);
      if (zoneData['data']?['is_deliverable'] != true) {
        emit(const HomeDeliveryNotAvailable());
        return;
      }
      final zoneId = zoneData['data']['zone_id'];

      // 2) Nearest store distance
      final storesUri = Uri.parse(
          '${AppConstant.baseUrl}delivery-zone/stores?latitude=${event.latitude}&longitude=${event.longitude}&per_page=20');
      final storesRes = await http.get(storesUri, headers: {'Accept': 'application/json'});
      if (storesRes.statusCode != 200) {
        emit(const HomeDeliveryError('Failed to fetch stores'));
        return;
      }
      final storesData = json.decode(storesRes.body);
      final List stores = storesData['data']?['data'] ?? [];
      if (stores.isEmpty) {
        emit(const HomeDeliveryNotAvailable());
        return;
      }

      // Sort by distance
      stores.sort((a, b) => (a['distance'] as num).compareTo(b['distance'] as num));
      final nearest = stores.first;
      final distanceKm = (nearest['distance'] as num).toDouble();

      // 3) ETA — cart if available, else products
      int? etaMinutes;
      if (event.token != null && event.token!.isNotEmpty) {
        final Map<String, String> qParams = {
          'latitude': event.latitude.toString(),
          'longitude': event.longitude.toString(),
        };
        if (event.addressId != null) {
          qParams['address_id'] = event.addressId.toString();
        }
        final cartUri = Uri.parse('${AppConstant.baseUrl}user/cart').replace(queryParameters: qParams);
        final cartRes = await http.get(cartUri, headers: {
          'Authorization': 'Bearer ${event.token}',
          'Accept': 'application/json',
        });
        if (cartRes.statusCode == 200) {
          final cartData = json.decode(cartRes.body);
          if (cartData['success'] == true && (cartData['data']?['items_count'] ?? 0) > 0) {
            etaMinutes = cartData['data']?['payment_summary']?['estimated_delivery_time'];
          }
        }
      }

      // If no cart ETA, fetch from products
      if (etaMinutes == null) {
        final productsUri = Uri.parse(
            '${AppConstant.baseUrl}products/random-categories?latitude=${event.latitude}&longitude=${event.longitude}&limit=20');
        final productsRes = await http.get(productsUri, headers: {'Accept': 'application/json'});
        if (productsRes.statusCode == 200) {
          final pData = json.decode(productsRes.body);
          final List products = pData['data']?['data'] ?? [];
          int? min;
          for (final p in products) {
            final eta = p['estimated_delivery_time'];
            if (eta is int) {
              min = min == null ? eta : (eta < min ? eta : min);
            }
          }
          etaMinutes = min;
        }
      }

      // 4) Address Label
      // Using the one passed in event, if we want to format it
      String label = event.addressLabel;
      if (label.isEmpty) {
        label = "Home";
      }

      emit(HomeDeliveryLoaded(
        zoneId: zoneId,
        nearestStoreName: nearest['name'].toString(),
        distanceKm: distanceKm,
        estimatedMinutes: etaMinutes ?? 0,
        addressLabel: label,
      ));
    } catch (e) {
      emit(HomeDeliveryError(e.toString()));
    }
  }
}

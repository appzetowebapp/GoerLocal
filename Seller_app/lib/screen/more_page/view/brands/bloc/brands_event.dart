part of 'brands_bloc.dart';

abstract class BrandsEvent {}

class LoadBrandsInitial extends BrandsEvent {
  final String? search;
  LoadBrandsInitial({this.search});
}

class LoadMoreBrands extends BrandsEvent {}

class RefreshBrands extends BrandsEvent {}

class SearchBrands extends BrandsEvent {
  final String query;
  SearchBrands(this.query);
}

class ClearBrands extends BrandsEvent {}

class AddBrandEvent extends BrandsEvent {
  final String title;
  final String description;
  final String imagePath;
  final String status;

  AddBrandEvent({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.status,
  });
}

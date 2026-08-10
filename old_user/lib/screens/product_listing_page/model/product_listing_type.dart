enum ProductListingType {
  category,
  brand,
  store,
  search,
  featuredSection,
  previouslyBought
}

extension ProductListingTypeX on ProductListingType {
  String get name {
    switch (this) {
      case ProductListingType.category:
        return 'category';
      case ProductListingType.brand:
        return 'brand';
      case ProductListingType.store:
        return 'store';
      case ProductListingType.search:
        return 'search';
      case ProductListingType.featuredSection:
        return 'feature_section';
      case ProductListingType.previouslyBought:
        return 'previously_bought';
    }
  }
}


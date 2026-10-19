/// Categorization of watch providers (powered by JustWatch / TMDB).
enum WatchProviderCategory {
  subscription('subscription', 'Subscription'),
  rent('rent', 'Rent'),
  buy('buy', 'Buy'),
  free('free', 'Free');

  final String code;
  final String label;

  const WatchProviderCategory(this.code, this.label);

  static WatchProviderCategory fromString(String? val) {
    if (val == null) return WatchProviderCategory.subscription;
    final lower = val.trim().toLowerCase();
    switch (lower) {
      case 'subscription':
      case 'flatrate':
      case 'stream':
        return WatchProviderCategory.subscription;
      case 'rent':
        return WatchProviderCategory.rent;
      case 'buy':
      case 'purchase':
        return WatchProviderCategory.buy;
      case 'free':
      case 'ads':
        return WatchProviderCategory.free;
      default:
        return WatchProviderCategory.subscription;
    }
  }
}

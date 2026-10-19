/// Strongly-typed domain metadata model for Place / Location entities.
class PlaceMetadata {
  final String? address;
  final String? location;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? placeType;
  final String? rating;
  final String? mapsUrl;
  final String? photoUrl;
  final String? phoneNumber;
  final String? openingHours;

  const PlaceMetadata({
    this.address,
    this.location,
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.placeType,
    this.rating,
    this.mapsUrl,
    this.photoUrl,
    this.phoneNumber,
    this.openingHours,
  });

  /// Formats the best human-readable location string available.
  String? get displayLocation {
    if (location != null && location!.isNotEmpty) return location;
    if (address != null && address!.isNotEmpty) return address;
    final parts = [city, state, country].where((s) => s != null && s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return null;
  }

  factory PlaceMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackTitle,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    double? parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return PlaceMetadata(
      location: meta['location']?.toString(),
      address: meta['address']?.toString() ?? meta['formatted_address']?.toString(),
      city: meta['city']?.toString(),
      state: meta['state']?.toString(),
      country: meta['country']?.toString(),
      latitude: parseDouble(meta['latitude'] ?? meta['lat']),
      longitude: parseDouble(meta['longitude'] ?? meta['lng']),
      placeType: meta['place_type']?.toString() ?? meta['type']?.toString(),
      rating: meta['rating']?.toString(),
      mapsUrl: meta['maps_url']?.toString() ?? meta['google_maps_url']?.toString(),
      photoUrl: meta['photo_url']?.toString() ?? meta['image_url']?.toString(),
      phoneNumber: meta['phone_number']?.toString() ?? meta['phone']?.toString(),
      openingHours: meta['opening_hours']?.toString(),
    );
  }
}

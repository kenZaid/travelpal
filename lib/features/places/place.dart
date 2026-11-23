import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final String category;
  final String description;
  final String history;
  final String address;
  final String openingHours;
  final String imageUrl;
  final double latitude;
  final double longitude;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.history,
    required this.address,
    required this.openingHours,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  LatLng get position {
    return LatLng(
      latitude,
      longitude,
    );
  }
}
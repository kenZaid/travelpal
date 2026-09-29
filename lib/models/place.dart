import 'package:latlong2/latlong.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;

  const Place({
    required this.id,
    required this.name,
    required this.description,
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
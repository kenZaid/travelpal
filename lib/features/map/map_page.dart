import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geofencing_api/geofencing_api.dart' as geofence;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../places/place_details_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int? selectedMarkerIndex;

  LatLng? userLocation;
  bool isLoadingLocation = false;

  String geofenceMessage = 'Geofences are starting...';

  // ------------------------------------------------------------
  // PLACE DATA
  // ------------------------------------------------------------

  static const List<Map<String, dynamic>> places = [
    {
      'id': 'jamboree_lake',
      'name': 'Jamboree Lake',
      'description':
          'A well-known natural landmark and freshwater lake in Muntinlupa.',
      'position': LatLng(
        14.386472,
        121.035833,
      ),
    },
    {
      'id': 'museo_ng_muntinlupa',
      'name': 'Museo ng Muntinlupa',
      'description':
          'A museum showcasing the history, culture, and heritage of Muntinlupa.',
      'position': LatLng(
        14.387417,
        121.046472,
      ),
    },
    {
      'id': 'new_bilibid_prison',
      'name': 'New Bilibid Prison',
      'description':
          'A major correctional facility and historical landmark in Muntinlupa.',
      'position': LatLng(
        14.382333,
        121.029861,
      ),
    },
  ];

  // 100-meter geofence around every place.
  static const double geofenceRadius = 100;

  @override
  void initState() {
    super.initState();

    _getUserLocation();
    _startGeofences();
  }

  // ------------------------------------------------------------
  // GPS LOCATION
  // ------------------------------------------------------------

  Future<void> _getUserLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    final serviceEnabled =
        await geo.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        isLoadingLocation = false;
      });
      return;
    }

    geo.LocationPermission permission =
        await geo.Geolocator.checkPermission();

    if (permission == geo.LocationPermission.denied) {
      permission =
          await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied ||
        permission ==
            geo.LocationPermission.deniedForever) {
      setState(() {
        isLoadingLocation = false;
      });
      return;
    }

    final position =
        await geo.Geolocator.getCurrentPosition();

    setState(() {
      userLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      isLoadingLocation = false;
    });
  }

  // ------------------------------------------------------------
  // GEOFENCE PERMISSION
  // ------------------------------------------------------------

  Future<bool> _requestGeofencePermission() async {
    if (!await geofence.Geofencing
        .instance.isLocationServicesEnabled) {
      return false;
    }

    geofence.LocationPermission permission =
        await geofence.Geofencing.instance
            .getLocationPermission();

    if (permission == geofence.LocationPermission.denied) {
      permission =
          await geofence.Geofencing.instance
              .requestLocationPermission();
    }

    if (permission == geofence.LocationPermission.denied ||
        permission ==
            geofence.LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ------------------------------------------------------------
  // GEOFENCE SETUP
  // ------------------------------------------------------------

  void _setupGeofencing() {
    try {
      geofence.Geofencing.instance.setup(
        interval: 5000,
        accuracy: 100,
        statusChangeDelay: 10000,
        allowsMockLocation: true,
        printsDebugLog: true,
      );
    } catch (e, s) {
      dev.log(
        'Geofence setup error: $e',
        stackTrace: s,
      );
    }
  }

  // ------------------------------------------------------------
  // START ALL GEOFENCES
  // ------------------------------------------------------------

  Future<void> _startGeofences() async {
    try {
      final permission =
          await _requestGeofencePermission();

      if (!permission) {
        if (mounted) {
          setState(() {
            geofenceMessage =
                'Location permission is required.';
          });
        }

        return;
      }

      _setupGeofencing();

      geofence.Geofencing.instance
          .addGeofenceStatusChangedListener(
        _onGeofenceStatusChanged,
      );

      geofence.Geofencing.instance
          .addGeofenceErrorCallbackListener(
        _onGeofenceError,
      );

      final regions = places.map((place) {
        final position = place['position'] as LatLng;

        return geofence.GeofenceRegion.circular(
          id: place['id'] as String,
          data: {
            'name': place['name'] as String,
          },
          center: geofence.LatLng(
            position.latitude,
            position.longitude,
          ),
          radius: geofenceRadius,
        );
      }).toSet();

      await geofence.Geofencing.instance.start(
        regions: regions,
      );

      if (mounted) {
        setState(() {
          geofenceMessage =
              '${places.length} geofences are active.';
        });
      }
    } catch (e, s) {
      dev.log(
        'Geofence start error: $e',
        stackTrace: s,
      );

      if (mounted) {
        setState(() {
          geofenceMessage =
              'Geofence error. Check the console.';
        });
      }
    }
  }

  // ------------------------------------------------------------
  // GEOFENCE EVENTS
  // ------------------------------------------------------------

  Future<void> _onGeofenceStatusChanged(
    geofence.GeofenceRegion region,
    geofence.GeofenceStatus status,
    geofence.Location location,
  ) async {
    dev.log(
      'Geofence: ${region.id} → ${status.name}',
    );

    if (!mounted) {
      return;
    }

    String placeName = region.id;

    if (region.data is Map) {
      final data = region.data as Map;

      if (data['name'] != null) {
        placeName = data['name'].toString();
      }
    }

    if (status == geofence.GeofenceStatus.enter) {
      setState(() {
        geofenceMessage =
            '📍 You are near $placeName!';
      });
    } else if (status == geofence.GeofenceStatus.exit) {
      setState(() {
        geofenceMessage =
            'You left the $placeName area.';
      });
    }
  }

  // ------------------------------------------------------------
  // GEOFENCE ERROR
  // ------------------------------------------------------------

  void _onGeofenceError(
    Object error,
    StackTrace stackTrace,
  ) {
    dev.log(
      'Geofence error: $error',
      stackTrace: stackTrace,
    );
  }

  // ------------------------------------------------------------
  // MAP UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const muntinlupa = LatLng(
      14.3855,
      121.0370,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muntinlupa Map'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: muntinlupa,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.travelpal.app',
              ),

              // ------------------------------------------------
              // USER LOCATION
              // ------------------------------------------------

              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

              // ------------------------------------------------
              // PLACE MARKERS
              // ------------------------------------------------

              MarkerLayer(
                markers: places
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final place = entry.value;

                  final position =
                      place['position'] as LatLng;

                  final isSelected =
                      selectedMarkerIndex == index;

                  return Marker(
                    point: position,
                    width: 55,
                    height: 55,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMarkerIndex = index;
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaceDetailsPage(
                              placeName:
                                  place['name'] as String,
                              description:
                                  place['description']
                                      as String,
                            ),
                          ),
                        );
                      },
                      child: AnimatedScale(
                        scale: isSelected ? 1.25 : 1.0,
                        duration:
                            const Duration(milliseconds: 200),
                        child: Container(
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(
                                        alpha: 0.20,
                                      ),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                )
                              : null,
                          child: Icon(
                            Icons.location_on,
                            size: isSelected ? 40 : 32,
                            color:
                                AppColors.secondaryRed,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ------------------------------------------------
          // LOCATION LOADING
          // ------------------------------------------------

          if (isLoadingLocation)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Getting location...',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ------------------------------------------------
          // GEOFENCE STATUS
          // ------------------------------------------------

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  geofenceMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------

  @override
  void dispose() {
    geofence.Geofencing.instance
        .removeGeofenceStatusChangedListener(
      _onGeofenceStatusChanged,
    );

    geofence.Geofencing.instance
        .removeGeofenceErrorCallbackListener(
      _onGeofenceError,
    );

    geofence.Geofencing.instance.stop();

    super.dispose();
  }
}
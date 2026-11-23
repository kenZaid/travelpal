import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geofencing_api/geofencing_api.dart' as geofence;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../../models/place_data.dart';
import '../../models/place.dart';
import '../places/place_details_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with TickerProviderStateMixin {
  int? selectedMarkerIndex;

  LatLng? userLocation;
  bool isLoadingLocation = false;

  // Realtime GPS tracking
  StreamSubscription<geo.Position>? _positionSubscription;

  String geofenceMessage = 'Geofences are starting...';

  Place? nearbyPlace;

  late final AnimationController _pulseController;

  final MapController _mapController = MapController();

  List<Polygon> muntinlupaBoundary = [];

  static const double geofenceRadius = 100;

  // ------------------------------------------------------------
  // PLACES
  // ------------------------------------------------------------

  List<Place> get allPlaces => PlaceData.places;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _loadMuntinlupaBoundary();
    _startLocationTracking();
    _startGeofences();
  }

  // ------------------------------------------------------------
  // MUNTINLUPA GEOJSON BOUNDARY
  // ------------------------------------------------------------

  Future<void> _loadMuntinlupaBoundary() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/maps/muntinlupa_boundary.geojson',
      );

      final Map<String, dynamic> geoJson =
          jsonDecode(jsonString);

      final List<dynamic> features =
          geoJson['features'] as List<dynamic>;

      final List<Polygon> polygons = [];

      for (final feature in features) {
        final geometry = feature['geometry'];

        if (geometry == null) {
          continue;
        }

        final String geometryType =
            geometry['type'] as String;

        final coordinates =
            geometry['coordinates'];

        if (geometryType == 'Polygon') {
          final List<dynamic> rings =
              coordinates as List<dynamic>;

          for (final ring in rings) {
            final points =
                _convertRingToLatLng(ring);

            if (points.length >= 3) {
              polygons.add(
                _createBoundaryPolygon(points),
              );
            }
          }
        } else if (geometryType == 'MultiPolygon') {
          final List<dynamic> multiPolygon =
              coordinates as List<dynamic>;

          for (final polygon in multiPolygon) {
            final List<dynamic> rings =
                polygon as List<dynamic>;

            for (final ring in rings) {
              final points =
                  _convertRingToLatLng(ring);

              if (points.length >= 3) {
                polygons.add(
                  _createBoundaryPolygon(points),
                );
              }
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        muntinlupaBoundary = polygons;
      });

      dev.log(
        'Muntinlupa boundary loaded: '
        '${polygons.length} polygon(s)',
      );
    } catch (e, s) {
      dev.log(
        'Failed to load Muntinlupa boundary: $e',
        stackTrace: s,
      );
    }
  }

  List<LatLng> _convertRingToLatLng(
    dynamic ring,
  ) {
    final List<dynamic> coordinates =
        ring as List<dynamic>;

    return coordinates.map<LatLng>((coordinate) {
      final List<dynamic> point =
          coordinate as List<dynamic>;

      final double longitude =
          (point[0] as num).toDouble();

      final double latitude =
          (point[1] as num).toDouble();

      return LatLng(
        latitude,
        longitude,
      );
    }).toList();
  }

  Polygon _createBoundaryPolygon(
    List<LatLng> points,
  ) {
    return Polygon(
      points: points,
      color: Colors.blue.withValues(
        alpha: 0.10,
      ),
      borderColor: Colors.blue,
      borderStrokeWidth: 3,
    );
  }

  // ------------------------------------------------------------
  // REALTIME USER LOCATION
  // ------------------------------------------------------------

  Future<bool> _prepareLocationPermission() async {
    final serviceEnabled =
        await geo.Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }

      return false;
    }

    geo.LocationPermission permission =
        await geo.Geolocator.checkPermission();

    if (permission ==
        geo.LocationPermission.denied) {
      permission =
          await geo.Geolocator.requestPermission();
    }

    if (permission ==
            geo.LocationPermission.denied ||
        permission ==
            geo.LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }

      return false;
    }

    return true;
  }

  Future<void> _startLocationTracking() async {
    if (mounted) {
      setState(() {
        isLoadingLocation = true;
      });
    }

    final permissionReady =
        await _prepareLocationPermission();

    if (!permissionReady) {
      return;
    }

    try {
      // Get the first location immediately.
      final initialPosition =
          await geo.Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          userLocation = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );

          isLoadingLocation = false;
        });
      }

      // Start continuous GPS tracking.
      // distanceFilter: 0 asks the platform to deliver every location
      // update it receives. The browser/device still controls how often
      // fresh GPS locations are actually provided.
      const locationSettings =
          geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 0,
      );

      // Cancel any previous stream before creating a new one.
      await _positionSubscription?.cancel();

      _positionSubscription =
          geo.Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (geo.Position position) {
          dev.log(
            'LIVE GPS UPDATE: '
            'lat=${position.latitude}, '
            'lng=${position.longitude}, '
            'accuracy=${position.accuracy}m',
          );

          if (!mounted) {
            return;
          }

          setState(() {
            userLocation = LatLng(
              position.latitude,
              position.longitude,
            );
            isLoadingLocation = false;
          });
        },
        onError: (error, stackTrace) {
          dev.log(
            'Realtime GPS stream error: $error',
            stackTrace: stackTrace,
          );

          if (mounted) {
            setState(() {
              isLoadingLocation = false;
            });
          }
        },
        onDone: () {
          dev.log('Realtime GPS stream ended.');
        },
      );

      dev.log('Realtime GPS stream subscription started.');
    } catch (e, s) {
      dev.log(
        'Failed to start realtime GPS: $e',
        stackTrace: s,
      );

      if (mounted) {
        setState(() {
          isLoadingLocation = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // MOVE MAP TO USER LOCATION
  // ------------------------------------------------------------

  Future<void> _goToCurrentLocation() async {
    if (userLocation != null) {
      _mapController.move(
        userLocation!,
        16,
      );
    } else {
      await _startLocationTracking();

      if (userLocation != null) {
        _mapController.move(
          userLocation!,
          16,
        );
      }
    }
  }

  // ------------------------------------------------------------
  // ZOOM CONTROLS
  // ------------------------------------------------------------

  void _zoomIn() {
    final currentZoom =
        _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut() {
    final currentZoom =
        _mapController.camera.zoom;

    _mapController.move(
      _mapController.camera.center,
      currentZoom - 1,
    );
  }

  // ------------------------------------------------------------
  // GEOFENCING
  // ------------------------------------------------------------

  Future<bool> _requestGeofencePermission() async {
    if (!await geofence.Geofencing.instance
        .isLocationServicesEnabled) {
      return false;
    }

    geofence.LocationPermission permission =
        await geofence.Geofencing.instance
            .getLocationPermission();

    if (permission ==
        geofence.LocationPermission.denied) {
      permission =
          await geofence.Geofencing.instance
              .requestLocationPermission();
    }

    if (permission ==
            geofence.LocationPermission.denied ||
        permission ==
            geofence.LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

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

      final regions = allPlaces.map((place) {
        return geofence.GeofenceRegion.circular(
          id: place.id,
          data: {
            'name': place.name,
          },
          center: geofence.LatLng(
            place.latitude,
            place.longitude,
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
              '${allPlaces.length} geofences are active.';
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

    final matchingPlaces = allPlaces.where(
      (place) => place.id == region.id,
    );

    final Place? matchedPlace = matchingPlaces.isNotEmpty
        ? matchingPlaces.first
        : null;

    if (status == geofence.GeofenceStatus.enter) {
      if (matchedPlace == null) {
        return;
      }

      setState(() {
        nearbyPlace = matchedPlace;
        geofenceMessage =
            '📍 You are near ${matchedPlace.name}!';
      });
    } else if (status == geofence.GeofenceStatus.exit) {
      setState(() {
        nearbyPlace = null;
        geofenceMessage = matchedPlace != null
            ? 'You left the ${matchedPlace.name} area.'
            : 'You left a nearby place area.';
      });
    }
  }

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
  // PLACE DETAILS
  // ------------------------------------------------------------

  void _openNearbyPlace() {
    if (nearbyPlace == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceDetailsPage(
          place: nearbyPlace!,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PULSING GREEN PLACE MARKER
  // ------------------------------------------------------------

  Marker _buildPulsingPlaceMarker(
    int index,
    Place place,
  ) {
    final LatLng position = LatLng(
      place.latitude,
      place.longitude,
    );

    final isSelected =
        selectedMarkerIndex == index;

    return Marker(
      point: position,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMarkerIndex = index;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailsPage(
                place: place,
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final pulse =
                _pulseController.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width:
                      44 + (pulse * 12),
                  height:
                      44 + (pulse * 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Colors.green.withValues(
                      alpha:
                          0.18 * (1 - pulse),
                    ),
                  ),
                ),
                Container(
                  width:
                      isSelected ? 18 : 14,
                  height:
                      isSelected ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.green.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    const muntinlupa = LatLng(
      14.3855,
      121.0370,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Muntinlupa Map',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: muntinlupa,
              initialZoom: 14,
            ),
            children: [
              // ------------------------------------------------
              // OPEN STREET MAP
              // ------------------------------------------------

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.travelpal.app',
              ),

              // ------------------------------------------------
              // MUNTINLUPA AREA
              // ------------------------------------------------

              if (muntinlupaBoundary.isNotEmpty)
                PolygonLayer(
                  polygons:
                      muntinlupaBoundary,
                  invertedFill:
                      Colors.black.withValues(
                    alpha: 0.25,
                  ),
                ),

              // ------------------------------------------------
              // USER LOCATION
              // ------------------------------------------------

              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration:
                            BoxDecoration(
                          color: Colors.blue
                              .withValues(
                            alpha: 0.2,
                          ),
                          shape:
                              BoxShape.circle,
                        ),
                        child:
                            const Icon(
                          Icons.my_location,
                          color:
                              Colors.blue,
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
                markers: allPlaces
                    .asMap()
                    .entries
                    .map(
                      (entry) =>
                          _buildPulsingPlaceMarker(
                        entry.key,
                        entry.value,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),

          // ----------------------------------------------------
          // ZOOM CONTROLS
          // ----------------------------------------------------

          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag:
                      'zoom_in_button',
                  backgroundColor:
                      Colors.white,
                  foregroundColor:
                      Colors.blue,
                  elevation: 5,
                  onPressed: _zoomIn,
                  child: const Icon(
                    Icons.add,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                FloatingActionButton.small(
                  heroTag:
                      'zoom_out_button',
                  backgroundColor:
                      Colors.white,
                  foregroundColor:
                      Colors.blue,
                  elevation: 5,
                  onPressed: _zoomOut,
                  child: const Icon(
                    Icons.remove,
                  ),
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // CURRENT LOCATION BUTTON
          // ----------------------------------------------------

          Positioned(
            right: 16,
            bottom: 130,
            child: FloatingActionButton(
              heroTag:
                  'current_location_button',
              backgroundColor:
                  Colors.white,
              foregroundColor:
                  Colors.blue,
              elevation: 5,
              onPressed:
                  _goToCurrentLocation,
              child: const Icon(
                Icons.my_location,
              ),
            ),
          ),

          // ----------------------------------------------------
          // GPS STREAM DEBUG STATUS
          // ----------------------------------------------------

          if (userLocation != null)
            Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    'GPS: ${userLocation!.latitude.toStringAsFixed(6)}, '
                    '${userLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // LOCATION LOADING
          // ----------------------------------------------------

          if (isLoadingLocation)
            const Positioned(
              top: 16,
              left: 16,
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Getting location...',
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // NEARBY PLACE CARD
          // ----------------------------------------------------

          if (nearbyPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: Card(
                elevation: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .all(8),
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .green
                                  .withValues(
                                alpha: 0.12,
                              ),
                              shape:
                                  BoxShape
                                      .circle,
                            ),
                            child:
                                const Icon(
                              Icons
                                  .location_on,
                              color:
                                  Colors.green,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          const Expanded(
                            child: Text(
                              'You are near!',
                              style:
                                  TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              setState(() {
                                nearbyPlace = null;

                                geofenceMessage =
                                    '${allPlaces.length} geofences are active.';
                              });
                            },
                            icon:
                                const Icon(
                              Icons.close,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        nearbyPlace!.name,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        nearbyPlace!.description,
                        maxLines: 2,
                        overflow:
                            TextOverflow
                                .ellipsis,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton(
                          onPressed:
                              _openNearbyPlace,
                          child:
                              const Text(
                            'View Place',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // GEOFENCE STATUS
          // ----------------------------------------------------

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                child: Text(
                  geofenceMessage,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
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
    _positionSubscription?.cancel();

    _pulseController.dispose();

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
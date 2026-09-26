import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

  @override
  Widget build(BuildContext context) {
    const muntinlupa = LatLng(14.3855, 121.0370);

    final places = [
      {
        'name': 'Jamboree Lake',
        'description':
            'A well-known natural landmark and freshwater lake in Muntinlupa.',
        'position': const LatLng(14.386472, 121.035833),
      },
      {
        'name': 'Museo ng Muntinlupa',
        'description':
            'A museum showcasing the history, culture, and heritage of Muntinlupa.',
        'position': const LatLng(14.387417, 121.046472),
      },
      {
        'name': 'New Bilibid Prison',
        'description':
            'A major correctional facility and historical landmark in Muntinlupa.',
        'position': const LatLng(14.382333, 121.029861),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muntinlupa Map'),
      ),
      body: FlutterMap(
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
          MarkerLayer(
            markers: places.asMap().entries.map((entry) {
              final index = entry.key;
              final place = entry.value;
              final isSelected = selectedMarkerIndex == index;

              return Marker(
                point: place['position'] as LatLng,
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
                        builder: (context) => PlaceDetailsPage(
                          placeName: place['name'] as String,
                          description: place['description'] as String,
                        ),
                      ),
                    );
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            )
                          : null,
                      child: Icon(
                        Icons.location_on,
                        size: isSelected ? 40 : 32,
                        color: AppColors.secondaryRed,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
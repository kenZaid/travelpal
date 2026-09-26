import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const muntinlupa = LatLng(14.3855, 121.0370);

    final places = [
      {
        'name': 'Jamboree Lake',
        'position': const LatLng(14.386472, 121.035833),
      },
      {
        'name': 'Museo ng Muntinlupa',
        'position': const LatLng(14.387417, 121.046472),
      },
      {
        'name': 'New Bilibid Prison',
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
            markers: places.map((place) {
              return Marker(
                point: place['position'] as LatLng,
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          place['name'] as String,
                        ),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.location_on,
                    size: 45,
                    color: AppColors.secondaryRed,
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
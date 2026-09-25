import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'place_details_page.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final places = [
      {
        'name': 'Jamboree Lake',
        'description': 'A well-known natural landmark in Muntinlupa.',
        'icon': Icons.water,
      },
      {
        'name': 'Museo ng Muntinlupa',
        'description': 'Explore the history and heritage of Muntinlupa.',
        'icon': Icons.museum,
      },
      {
        'name': 'New Bilibid Prison',
        'description': 'A significant historical landmark in Muntinlupa.',
        'icon': Icons.account_balance,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Places'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: Icon(
                  place['icon'] as IconData,
                  color: Colors.white,
                ),
              ),
              title: Text(
                place['name'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  place['description'] as String,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () {
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
            ),
          );
        },
      ),
    );
  }
}
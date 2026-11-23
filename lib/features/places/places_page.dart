
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/place.dart';
import '../../models/place_data.dart';
import 'place_details_page.dart';

class PlacesPage extends StatelessWidget {
  const PlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: PlaceData.places.length,
        itemBuilder: (context, index) {
          final Place place = PlaceData.places[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                ),
              ),
              title: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  place.description,
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
                      place: place,
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

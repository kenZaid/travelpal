import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PlaceDetailsPage extends StatelessWidget {
  final String placeName;
  final String description;

  const PlaceDetailsPage({
    super.key,
    required this.placeName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image,
                  size: 70,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              placeName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.secondaryRed,
                ),
                SizedBox(width: 8),
                Text(
                  'Muntinlupa City',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add to Itinerary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
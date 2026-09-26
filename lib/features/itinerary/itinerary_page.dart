import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  final List<Map<String, dynamic>> _itinerary = [
    {
      'place': 'Jamboree Lake',
      'date': DateTime.now(),
      'time': const TimeOfDay(hour: 10, minute: 0),
    },
  ];

  final List<String> _availablePlaces = [
    'Jamboree Lake',
    'Museo ng Muntinlupa',
    'New Bilibid Prison',
  ];

  Future<void> _showAddPlaceDialog() async {
    String? selectedPlace;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Place'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Place',
                    ),
                    items: _availablePlaces.map((place) {
                      return DropdownMenuItem(
                        value: place,
                        child: Text(place),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPlace = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        initialDate: DateTime.now(),
                      );

                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      selectedTime == null
                          ? 'Select Time'
                          : selectedTime!.format(context),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );

                      if (time != null) {
                        setDialogState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedPlace != null &&
                          selectedDate != null &&
                          selectedTime != null
                      ? () {
                          setState(() {
                            _itinerary.add({
                              'place': selectedPlace,
                              'date': selectedDate,
                              'time': selectedTime,
                            });
                          });

                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Itinerary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Trip',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Plan and organize the places you want to visit.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._itinerary.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            final place = item['place'] as String;
            final date = item['date'] as DateTime;
            final time = item['time'] as TimeOfDay;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(
                    Icons.place,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  place,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_formatDate(date)} • ${time.format(context)}',
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _itinerary.removeAt(index);
                    });
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddPlaceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Place'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/place_data.dart';
import 'itinerary_data.dart';

class ItineraryPage extends StatefulWidget {
  const ItineraryPage({super.key});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    ItineraryData.changes.addListener(_onItineraryChanged);
    _loadItinerary();
  }

  @override
  void dispose() {
    ItineraryData.changes.removeListener(_onItineraryChanged);
    super.dispose();
  }

  void _onItineraryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadItinerary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ItineraryData.loadPlaces();
    } catch (e) {
      _errorMessage = 'Unable to load your itinerary. Please try again.';
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showAddPlaceDialog() async {
    String? selectedPlace;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (dialogContext) {
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
                    isExpanded: true,
                    items: PlaceData.places.map((place) {
                      return DropdownMenuItem<String>(
                        value: place.name,
                        child: Text(
                          place.name,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed:
                      selectedPlace != null &&
                          selectedDate != null &&
                          selectedTime != null
                      ? () async {
                          if (ItineraryData.containsPlace(
                            selectedPlace!,
                          )) {
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This place is already in your itinerary.',
                                ),
                              ),
                            );

                            return;
                          }

                          final selectedPlaceData = PlaceData.places
                              .firstWhere(
                                (place) =>
                                    place.name == selectedPlace,
                              );

                          try {
                            await ItineraryData.addPlace(
                              place: selectedPlaceData.name,
                              description: selectedPlaceData.description,
                              date: selectedDate!,
                              time: selectedTime!.format(context),
                            );

                            if (!mounted || !dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext);

                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Place added to your itinerary!',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add place: $e',
                                ),
                              ),
                            );
                          }
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

  Future<void> _showEditDialog(int index) async {
    final item = ItineraryData.items[index];

    DateTime selectedDate = item['date'] as DateTime;
    String selectedTime = item['time'] as String;

    TimeOfDay timeOfDay = _parseTime(selectedTime);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${item['place']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        initialDate: selectedDate,
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
                    title: Text(timeOfDay.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: timeOfDay,
                      );

                      if (time != null) {
                        setDialogState(() {
                          timeOfDay = time;
                          selectedTime = time.format(context);
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ItineraryData.updatePlace(
                        index: index,
                        date: selectedDate,
                        time: selectedTime,
                      );

                      if (!mounted || !dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Itinerary updated successfully!',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(
                        this.context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update itinerary: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePlace(int index) async {
    try {
      await ItineraryData.removePlace(index);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Place removed from itinerary.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete place: $e'),
        ),
      );
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(' ');
    final timeParts = parts[0].split(':');

    int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    if (parts.length > 1) {
      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = ItineraryData.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Itinerary'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadItinerary,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
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

                    if (itinerary.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 60,
                                color: AppColors.primaryBlue,
                              ),

                              SizedBox(height: 12),

                              Text(
                                'Your itinerary is empty.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 6),

                              Text(
                                'Add places that you want to visit.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                    ...itinerary.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final place = item['place'] as String;
                      final description = item['description'] as String;
                      final date = item['date'] as DateTime;
                      final time = item['time'] as String;

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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                Wrap(
                                  spacing: 14,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(_formatDate(date)),
                                      ],
                                    ),

                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(time),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(index);
                              }

                              if (value == 'delete') {
                                _deletePlace(index);
                              }
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),

                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ];
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

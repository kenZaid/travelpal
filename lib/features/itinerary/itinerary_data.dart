class ItineraryData {
  static final List<Map<String, dynamic>> items = [];

  static void addPlace({
    required String place,
    required String description,
    required DateTime date,
    required String time,
  }) {
    items.add({
      'place': place,
      'description': description,
      'date': date,
      'time': time,
    });
  }

  static void removePlace(int index) {
    items.removeAt(index);
  }

  static bool containsPlace(String place) {
    return items.any(
      (item) => item['place'] == place,
    );
  }
}
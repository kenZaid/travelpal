import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItineraryData {
  static final List<Map<String, dynamic>> items = [];

  // Notifies the UI whenever itinerary data changes.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  // Gets the current user's itinerary collection.
  static CollectionReference<Map<String, dynamic>> get _collection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No user is currently logged in.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('itinerary');
  }

  // Loads saved itinerary entries from Firestore.
  static Future<void> loadPlaces() async {
    final snapshot = await _collection.get();

    items.clear();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      items.add({
        'id': doc.id,
        'place': data['place'],
        'description': data['description'],
        'date': (data['date'] as Timestamp).toDate(),
        'time': data['time'],
      });
    }

    changes.value++;
  }

  // Adds a new itinerary entry to Firestore.
  static Future<void> addPlace({
    required String place,
    required String description,
    required DateTime date,
    required String time,
  }) async {
    if (containsPlace(place)) {
      throw StateError('This place is already in your itinerary.');
    }

    final doc = await _collection.add({
      'place': place,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
    });

    items.add({
      'id': doc.id,
      'place': place,
      'description': description,
      'date': date,
      'time': time,
    });

    changes.value++;
  }

  // Updates an existing itinerary entry.
  static Future<void> updatePlace({
    required int index,
    required DateTime date,
    required String time,
  }) async {
    final item = items[index];
    final id = item['id'] as String;

    await _collection.doc(id).update({
      'date': Timestamp.fromDate(date),
      'time': time,
    });

    item['date'] = date;
    item['time'] = time;

    changes.value++;
  }

  // Deletes an itinerary entry from Firestore.
  static Future<void> removePlace(int index) async {
    final item = items[index];
    final id = item['id'] as String;

    await _collection.doc(id).delete();

    items.removeAt(index);

    changes.value++;
  }

  // Checks whether a place is already in the itinerary.
  static bool containsPlace(String place) {
    return items.any(
      (item) => item['place'] == place,
    );
  }
}

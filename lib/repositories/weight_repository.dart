import 'package:flutter/foundation.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/database/firebase_helper.dart';
import 'package:metabolic/models/weight_entry.dart';

class WeightRepository {
  static final WeightRepository _instance = WeightRepository._internal();
  factory WeightRepository() => _instance;
  WeightRepository._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final FirebaseHelper _firebase = FirebaseHelper();

  /// Saves weight to local SQLite database and attempts to sync to Firebase.
  /// If Firebase sync fails (e.g. offline), it gracefully ignores the error,
  /// as data is already safely stored locally and can be synced later.
  Future<void> saveWeight(DateTime date, double weight, {String? note}) async {
    // 1. Instantly save to local offline-first SQLite database
    await _db.insertOrUpdateWeight(date, weight, note: note);

    // 2. Attempt to background sync to Firebase
    final entry = WeightEntry(date: date, weight: weight, note: note);
    try {
      await _firebase.syncSingleWeight(entry);
    } catch (e) {
      // Gracefully handle offline scenarios. The user's data is safe in SQLite.
      debugPrint('Firebase sync delayed (likely offline): $e');
    }
  }

  /// Retrieves a specific weight entry for a given date from the local database.
  Future<WeightEntry?> getWeightForDate(DateTime date) async {
    return await _db.getWeightForDate(date);
  }

  /// Retrieves all weight entries from the local database, ordered by date.
  Future<List<WeightEntry>> getAllWeights() async {
    return await _db.getAllWeights();
  }

  /// Retrieves weight entries within a specific date range.
  Future<List<WeightEntry>> getWeightsInRange(DateTime start, DateTime end) async {
    return await _db.getWeightsInRange(start, end);
  }
}

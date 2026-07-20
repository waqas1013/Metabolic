
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/models/weight_entry.dart';

class FirebaseHelper {
  static final FirebaseHelper _instance = FirebaseHelper._internal();
  factory FirebaseHelper() => _instance;
  FirebaseHelper._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get userEmail => _auth.currentUser?.email;

  /// Create a new account with email & password, then sync local data to cloud.
  Future<User?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Push any existing local data to the new cloud account
    await syncToCloud();
    return credential.user;
  }

  /// Sign in to an existing account, then pull cloud data to local.
  Future<User?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Pull backed-up data from Cloud to SQLite
    await syncFromCloud();
    return credential.user;
  }

  /// Pull workouts from Cloud (Firestore -> SQLite)
  Future<void> syncFromCloud() async {
    final user = currentUser;
    if (user == null) return;

    final db = DatabaseHelper();

    // 1. Fetch library from cloud
    final librarySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('library')
        .get();

    for (final doc in librarySnapshot.docs) {
      final name = doc.id;
      await db.addExerciseToLibraryFromSync(name);
    }

    // 2. Fetch workouts from cloud
    final workoutsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .get();

    for (final doc in workoutsSnapshot.docs) {
      final data = doc.data();
      final dateStr = doc.id;
      final date = DateTime.parse(dateStr);

      // Check if this workout already exists locally
      final exists = await db.hasEntryForDate(date);
      if (!exists) {
        final entry = WorkoutEntry(
          date: date,
          energy: data['energy'] as int,
          enjoyment: data['enjoyment'] as int,
          backComfort: data['backComfort'] as int,
          difficulty: data['difficulty'] as int,
          improvement: data['improvement'] as String? ?? 'No notes',
          type: data['type'] as String? ?? 'Gym',
          distance: (data['distance'] as num?)?.toDouble(),
          duration: data['duration'] as int?,
        );

        final List<ExerciseLog> exercises = [];
        if (data['exercises'] != null) {
          final list = data['exercises'] as List<dynamic>;
          for (final item in list) {
            final map = Map<String, dynamic>.from(item as Map);
            exercises.add(ExerciseLog(
              name: map['name'] as String,
              weight: (map['weight'] as num).toDouble(),
              unit: map['unit'] as String,
              reps: map['reps'] as int? ?? 0,
            ));
          }
        }

        await db.insertEntryFromSync(entry, exercises);
      }
    }

    // 3. Fetch body weights from cloud
    final weightsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weights')
        .get();

    for (final doc in weightsSnapshot.docs) {
      final data = doc.data();
      final date = DateTime.parse(doc.id);
      final entry = WeightEntry(
        date: date,
        weight: (data['weight'] as num).toDouble(),
        note: data['note'] as String?,
      );
      await db.insertWeightFromSync(entry);
    }
  }

  /// Push local workouts to Cloud (SQLite -> Firestore)
  Future<void> syncToCloud() async {
    final user = currentUser;
    if (user == null) return;

    final db = DatabaseHelper();

    // 1. Sync Library
    final library = await db.getExerciseLibrary();
    for (final name in library) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('library')
          .doc(name)
          .set({'syncedAt': FieldValue.serverTimestamp()});
    }

    // 2. Sync Workouts
    final allEntries = await db.getAllEntriesWithExercises();
    for (final item in allEntries) {
      final entry = item['entry'] as WorkoutEntry;
      final exercises = item['exercises'] as List<ExerciseLog>;

      final dateStr = entry.date.toIso8601String();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .doc(dateStr)
          .set({
        'energy': entry.energy,
        'enjoyment': entry.enjoyment,
        'backComfort': entry.backComfort,
        'difficulty': entry.difficulty,
        'improvement': entry.improvement,
        'type': entry.type,
        'distance': entry.distance,
        'duration': entry.duration,
        'exercises': exercises.map((e) => {
          'name': e.name,
          'weight': e.weight,
          'unit': e.unit,
          'reps': e.reps,
        }).toList(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Sync body weights
    final allWeights = await db.getAllWeights();
    for (final w in allWeights) {
      final dateStr = '${w.date.year}-${w.date.month.toString().padLeft(2, '0')}-${w.date.day.toString().padLeft(2, '0')}';
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weights')
          .doc(dateStr)
          .set({
        'weight': w.weight,
        'note': w.note,
        'syncedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Sync a single workout directly
  Future<void> syncSingleWorkout(WorkoutEntry entry, List<ExerciseLog> exercises) async {
    final user = currentUser;
    if (user == null) return;

    final dateStr = entry.date.toIso8601String();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .doc(dateStr)
        .set({
      'energy': entry.energy,
      'enjoyment': entry.enjoyment,
      'backComfort': entry.backComfort,
      'difficulty': entry.difficulty,
      'improvement': entry.improvement,
      'type': entry.type,
      'distance': entry.distance,
      'duration': entry.duration,
      'exercises': exercises.map((e) => {
        'name': e.name,
        'weight': e.weight,
        'unit': e.unit,
        'reps': e.reps,
      }).toList(),
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sync single library item
  Future<void> syncSingleLibraryItem(String name) async {
    final user = currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('library')
        .doc(name)
        .set({'syncedAt': FieldValue.serverTimestamp()});
  }

  /// Delete workout from Cloud
  Future<void> deleteWorkoutFromCloud(DateTime date) async {
    final user = currentUser;
    if (user == null) return;

    final dateStr = date.toIso8601String();
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('workouts')
        .doc(dateStr)
        .delete();
  }

  /// Sync a single body weight entry to cloud
  Future<void> syncSingleWeight(WeightEntry entry) async {
    final user = currentUser;
    if (user == null) return;

    final dateStr = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('weights')
        .doc(dateStr)
        .set({
      'weight': entry.weight,
      'note': entry.note,
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
    await DatabaseHelper().clearAllData();
  }
}

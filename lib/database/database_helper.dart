import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/models/weight_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Future<Database>? _dbInitFuture;

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_dbInitFuture != null) {
      _database = await _dbInitFuture;
      return _database!;
    }
    _dbInitFuture = _initDatabase();
    _database = await _dbInitFuture;
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_journal.db');

    return await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workout_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        energy INTEGER NOT NULL,
        enjoyment INTEGER NOT NULL,
        backComfort INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        improvement TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'Gym',
        distance REAL,
        duration INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        weight REAL NOT NULL,
        unit TEXT NOT NULL,
        reps INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (entryId) REFERENCES workout_entries(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_library(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE body_weights(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        weight REAL NOT NULL,
        note TEXT
      )
    ''');

    final defaultExercises = [
      'Standard or Incline Push-ups',
      'Assisted Pull-ups',
      'Lat Pulldown Machine',
      'Glute Bridges',
      'Cable Face Pulls',
      'Bird-Dog',
      'Dead Hang',
      'Incline Dumbbell Press',
      'Seated Cable Row',
      'Goblet Squat',
      'Dumbbell Lateral Raises',
      'Bicep Curls',
      'Tricep Pushdowns',
      'Dumbbell Reverse Lunges',
      'Heavy Farmer\'s Carries',
      'Pallof Press',
      'Pull-ups',
      'Push-ups',
      'Squats',
      'Dips',
      'Deadlift',
      'Bench Press',
      'Overhead Press',
      'Barbell Row',
      'Lunge',
      'Plank'
    ];
    for (final name in defaultExercises) {
      await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [name]);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE exercise_logs ADD COLUMN reps INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE workout_entries ADD COLUMN type TEXT NOT NULL DEFAULT 'Gym'");
      await db.execute("ALTER TABLE workout_entries ADD COLUMN distance REAL");
      await db.execute("ALTER TABLE workout_entries ADD COLUMN duration INTEGER");
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercise_library(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('DELETE FROM exercise_library');
      final defaultExercises = [
        'Standard or Incline Push-ups',
        'Assisted Pull-ups',
        'Lat Pulldown Machine',
        'Glute Bridges',
        'Cable Face Pulls',
        'Bird-Dog',
        'Dead Hang',
        'Incline Dumbbell Press',
        'Seated Cable Row',
        'Goblet Squat',
        'Dumbbell Lateral Raises',
        'Bicep Curls',
        'Tricep Pushdowns',
        'Dumbbell Reverse Lunges',
        'Heavy Farmer\'s Carries',
        'Pallof Press',
        'Pull-ups',
        'Push-ups',
        'Squats',
        'Dips',
        'Deadlift',
        'Bench Press',
        'Overhead Press',
        'Barbell Row',
        'Lunge',
        'Plank'
      ];
      for (final name in defaultExercises) {
        await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [name]);
      }
    }
    if (oldVersion < 5) {
      await db.execute('DELETE FROM exercise_library');
      final defaultExercises = [
        'Standard or Incline Push-ups',
        'Assisted Pull-ups',
        'Lat Pulldown Machine',
        'Glute Bridges',
        'Cable Face Pulls',
        'Bird-Dog',
        'Dead Hang',
        'Incline Dumbbell Press',
        'Seated Cable Row',
        'Goblet Squat',
        'Dumbbell Lateral Raises',
        'Bicep Curls',
        'Tricep Pushdowns',
        'Dumbbell Reverse Lunges',
        'Heavy Farmer\'s Carries',
        'Pallof Press',
        'Pull-ups',
        'Push-ups',
        'Squats',
        'Dips',
        'Deadlift',
        'Bench Press',
        'Overhead Press',
        'Barbell Row',
        'Lunge',
        'Plank'
      ];
      for (final name in defaultExercises) {
        await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [name]);
      }
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings(
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS body_weights(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          weight REAL NOT NULL,
          note TEXT
        )
      ''');
    }
  }

  Future<int> insertEntry(WorkoutEntry entry, List<ExerciseLog> exercises) async {
    final db = await database;
    final entryId = await db.insert('workout_entries', entry.toMap()..remove('id'));

    for (final exercise in exercises) {
      await db.insert('exercise_logs', {
        'entryId': entryId,
        'name': exercise.name,
        'weight': exercise.weight,
        'unit': exercise.unit,
        'reps': exercise.reps,
      });
      // Automatically add to library if not exists
      await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [exercise.name]);
    }

    return entryId;
  }

  Future<List<WorkoutEntry>> getAllEntries() async {
    final db = await database;
    final maps = await db.query('workout_entries', orderBy: 'date DESC');
    return maps.map((map) => WorkoutEntry.fromMap(map)).toList();
  }

  Future<List<ExerciseLog>> getExercisesForEntry(int entryId) async {
    final db = await database;
    final maps = await db.query(
      'exercise_logs',
      where: 'entryId = ?',
      whereArgs: [entryId],
    );
    return maps.map((map) => ExerciseLog.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllEntriesWithExercises() async {
    final db = await database;
    final entries = await db.query('workout_entries', orderBy: 'date DESC');
    final result = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final exercises = await db.query(
        'exercise_logs',
        where: 'entryId = ?',
        whereArgs: [entry['id']],
      );
      result.add({
        'entry': WorkoutEntry.fromMap(entry),
        'exercises': exercises.map((e) => ExerciseLog.fromMap(e)).toList(),
      });
    }

    return result;
  }

  Future<List<String>> getDistinctExerciseNames() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT name FROM exercise_logs ORDER BY name');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getWeightProgressionForExercise(String exerciseName) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.date, el.weight, el.unit, el.reps
      FROM exercise_logs el
      JOIN workout_entries e ON el.entryId = e.id
      WHERE el.name = ?
      ORDER BY e.date ASC
    ''', [exerciseName]);
  }

  Future<void> updateEntry(WorkoutEntry entry, List<ExerciseLog> exercises) async {
    final db = await database;
    await db.update(
      'workout_entries',
      entry.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    // Delete old exercises and re-insert updated ones
    await db.delete('exercise_logs', where: 'entryId = ?', whereArgs: [entry.id]);
    for (final exercise in exercises) {
      await db.insert('exercise_logs', {
        'entryId': entry.id,
        'name': exercise.name,
        'weight': exercise.weight,
        'unit': exercise.unit,
        'reps': exercise.reps,
      });
      await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [exercise.name]);
    }
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    await db.delete('exercise_logs', where: 'entryId = ?', whereArgs: [id]);
    return await db.delete('workout_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getExerciseLibrary() async {
    final db = await database;
    final maps = await db.query('exercise_library', orderBy: 'name ASC');
    return maps.map((m) => m['name'] as String).toList();
  }

  Future<bool> hasEntryForDate(DateTime date) async {
    final db = await database;
    final maps = await db.query(
      'workout_entries',
      where: 'date = ?',
      whereArgs: [date.toIso8601String()],
    );
    return maps.isNotEmpty;
  }

  Future<void> addExerciseToLibraryFromSync(String name) async {
    final db = await database;
    await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [name]);
  }

  Future<void> insertEntryFromSync(WorkoutEntry entry, List<ExerciseLog> exercises) async {
    final db = await database;
    final entryId = await db.insert('workout_entries', entry.toMap()..remove('id'));
    for (final exercise in exercises) {
      await db.insert('exercise_logs', {
        'entryId': entryId,
        'name': exercise.name,
        'weight': exercise.weight,
        'unit': exercise.unit,
        'reps': exercise.reps,
      });
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('exercise_logs');
    await db.delete('workout_entries');
    await db.delete('exercise_library');
    await db.delete('app_settings');
    await db.delete('body_weights');

    final defaultExercises = [
      'Standard or Incline Push-ups',
      'Assisted Pull-ups',
      'Lat Pulldown Machine',
      'Glute Bridges',
      'Cable Face Pulls',
      'Bird-Dog',
      'Dead Hang',
      'Incline Dumbbell Press',
      'Seated Cable Row',
      'Goblet Squat',
      'Dumbbell Lateral Raises',
      'Bicep Curls',
      'Tricep Pushdowns',
      'Dumbbell Reverse Lunges',
      'Heavy Farmer\'s Carries',
      'Pallof Press',
      'Pull-ups',
      'Push-ups',
      'Squats',
      'Dips',
      'Deadlift',
      'Bench Press',
      'Overhead Press',
      'Barbell Row',
      'Lunge',
      'Plank'
    ];
    for (final name in defaultExercises) {
      await db.rawInsert('INSERT OR IGNORE INTO exercise_library(name) VALUES(?)', [name]);
    }
  }

  // ───────────── Body Weight CRUD ─────────────

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> insertOrUpdateWeight(DateTime date, double weight, {String? note}) async {
    final db = await database;
    await db.insert(
      'body_weights',
      {'date': _dateKey(date), 'weight': weight, 'note': note},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<WeightEntry?> getWeightForDate(DateTime date) async {
    final db = await database;
    final maps = await db.query(
      'body_weights',
      where: 'date = ?',
      whereArgs: [_dateKey(date)],
    );
    if (maps.isEmpty) return null;
    return WeightEntry.fromMap(maps.first);
  }

  Future<List<WeightEntry>> getAllWeights() async {
    final db = await database;
    final maps = await db.query('body_weights', orderBy: 'date ASC');
    return maps.map((m) => WeightEntry.fromMap(m)).toList();
  }

  Future<List<WeightEntry>> getWeightsInRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'body_weights',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
      orderBy: 'date ASC',
    );
    return maps.map((m) => WeightEntry.fromMap(m)).toList();
  }

  Future<void> deleteWeight(DateTime date) async {
    final db = await database;
    await db.delete('body_weights', where: 'date = ?', whereArgs: [_dateKey(date)]);
  }

  Future<void> insertWeightFromSync(WeightEntry entry) async {
    final db = await database;
    await db.insert(
      'body_weights',
      entry.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}

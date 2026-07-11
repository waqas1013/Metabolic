import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:metabolic/models/workout_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_journal.db');

    return await openDatabase(
      path,
      version: 3,
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

  Future<int> deleteEntry(int id) async {
    final db = await database;
    await db.delete('exercise_logs', where: 'entryId = ?', whereArgs: [id]);
    return await db.delete('workout_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}

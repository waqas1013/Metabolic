class WorkoutEntry {
  final int? id;
  final DateTime date;
  final int energy;
  final int enjoyment;
  final int backComfort;
  final int difficulty;
  final String improvement;
  final String type; // 'Gym', 'Walk', 'Badminton', 'Other'
  final double? distance; // in km
  final int? duration; // in minutes

  const WorkoutEntry({
    this.id,
    required this.date,
    required this.energy,
    required this.enjoyment,
    required this.backComfort,
    required this.difficulty,
    required this.improvement,
    this.type = 'Gym',
    this.distance,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'energy': energy,
      'enjoyment': enjoyment,
      'backComfort': backComfort,
      'difficulty': difficulty,
      'improvement': improvement,
      'type': type,
      'distance': distance,
      'duration': duration,
    };
  }

  factory WorkoutEntry.fromMap(Map<String, dynamic> map) {
    return WorkoutEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      energy: map['energy'] as int,
      enjoyment: map['enjoyment'] as int,
      backComfort: map['backComfort'] as int,
      difficulty: map['difficulty'] as int,
      improvement: map['improvement'] as String,
      type: map['type'] as String? ?? 'Gym',
      distance: (map['distance'] as num?)?.toDouble(),
      duration: map['duration'] as int?,
    );
  }

  WorkoutEntry copyWith({
    int? id,
    DateTime? date,
    int? energy,
    int? enjoyment,
    int? backComfort,
    int? difficulty,
    String? improvement,
    String? type,
    double? distance,
    int? duration,
  }) {
    return WorkoutEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      energy: energy ?? this.energy,
      enjoyment: enjoyment ?? this.enjoyment,
      backComfort: backComfort ?? this.backComfort,
      difficulty: difficulty ?? this.difficulty,
      improvement: improvement ?? this.improvement,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
    );
  }
}

class ExerciseLog {
  final int? id;
  final int? entryId;
  final String name;
  final double weight;
  final String unit;
  final int reps;

  const ExerciseLog({
    this.id,
    this.entryId,
    required this.name,
    required this.weight,
    required this.unit,
    required this.reps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryId': entryId,
      'name': name,
      'weight': weight,
      'unit': unit,
      'reps': reps,
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] as int?,
      entryId: map['entryId'] as int?,
      name: map['name'] as String,
      weight: (map['weight'] as num).toDouble(),
      unit: map['unit'] as String,
      reps: (map['reps'] as int? ?? 0),
    );
  }
}

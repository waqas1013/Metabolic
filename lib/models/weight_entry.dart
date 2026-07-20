class WeightEntry {
  final int? id;
  final DateTime date;
  final double weight;
  final String? note;

  const WeightEntry({
    this.id,
    required this.date,
    required this.weight,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'weight': weight,
      'note': note,
    };
  }

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      weight: (map['weight'] as num).toDouble(),
      note: map['note'] as String?,
    );
  }

  WeightEntry copyWith({
    int? id,
    DateTime? date,
    double? weight,
    String? note,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }
}

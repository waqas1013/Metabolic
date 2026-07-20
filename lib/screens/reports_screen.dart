import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allData = [];
  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getStartOfWeek(DateTime.now());
    _loadData();
  }

  void refresh() {
    _loadData();
  }

  DateTime _getStartOfWeek(DateTime date) {
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper().getAllEntriesWithExercises();
    setState(() {
      _allData = data;
      _isLoading = false;
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  /// Filter entries that fall within [weekStart, weekStart+6 days].
  List<Map<String, dynamic>> _entriesForWeek(DateTime weekStart) {
    final weekEnd = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day + 6,
      23,
      59,
      59,
    );
    return _allData.where((d) {
      final entry = d['entry'] as WorkoutEntry;
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return !entryDate.isBefore(weekStart) && !entryDate.isAfter(weekEnd);
    }).toList()
      ..sort((a, b) =>
          (a['entry'] as WorkoutEntry).date.compareTo((b['entry'] as WorkoutEntry).date));
  }

  String _generateReportText() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final prevWeekStart = _currentWeekStart.subtract(const Duration(days: 7));

    final currentWeekData = _entriesForWeek(_currentWeekStart);
    final prevWeekData = _entriesForWeek(prevWeekStart);

    final dateRangeStr =
        '${DateFormat('MMM d').format(_currentWeekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';

    if (currentWeekData.isEmpty) {
      return 'WEEKLY WORKOUT SUMMARY\n'
          '📅 $dateRangeStr\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
          'No sessions recorded this week.';
    }

    // --- Aggregate counts and totals ---
    final typeCounts = <String, int>{};
    double totalEnergy = 0;
    double totalEnjoyment = 0;
    double totalDifficulty = 0;
    double totalBack = 0;
    final totalSessions = currentWeekData.length;

    for (var d in currentWeekData) {
      final entry = d['entry'] as WorkoutEntry;
      typeCounts[entry.type] = (typeCounts[entry.type] ?? 0) + 1;
      totalEnergy += entry.energy;
      totalEnjoyment += entry.enjoyment;
      totalDifficulty += entry.difficulty;
      totalBack += entry.backComfort;
    }

    final typeString =
        typeCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ');

    // --- Build report text ---
    final buf = StringBuffer();
    buf.writeln('WEEKLY WORKOUT SUMMARY');
    buf.writeln('📅 $dateRangeStr');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    buf.writeln('🏋️ Total Sessions: $totalSessions ($typeString)\n');

    buf.writeln('📈 SCALE REFERENCE (1–10):');
    buf.writeln('* Energy: 1 = exhausted, 10 = fully energized');
    buf.writeln('* Enjoyment: 1 = hated it, 10 = loved it');
    buf.writeln('* Difficulty (RPE): 1 = very easy, 10 = max effort');
    buf.writeln('* Back Comfort: 0 = no issues, 10 = severe pain\n');

    buf.writeln('📅 SESSION DETAILS:');
    buf.writeln('───────────────────');

    final dayFmt = DateFormat('EEE, MMM d');

    for (var d in currentWeekData) {
      final entry = d['entry'] as WorkoutEntry;
      final exercises = d['exercises'] as List<ExerciseLog>;

      buf.writeln('🗓️ ${dayFmt.format(entry.date)} — ${entry.type}');

      // Distance / Duration for walks etc.
      if (entry.distance != null || entry.duration != null) {
        final parts = <String>[];
        if (entry.distance != null) {
          parts.add('Distance: ${entry.distance!.toStringAsFixed(1)} km');
        }
        if (entry.duration != null) {
          parts.add('Duration: ${entry.duration} min');
        }
        buf.writeln('  ${parts.join(' | ')}');
      }

      buf.writeln(
          '  Energy: ${entry.energy} | Enjoyment: ${entry.enjoyment} | Difficulty: ${entry.difficulty} | Back: ${entry.backComfort}');

      if (exercises.isNotEmpty) {
        buf.writeln('  Exercises:');
        for (var ex in exercises) {
          final weightStr = ex.weight == 0
              ? 'BW'
              : '${_formatNumber(ex.weight)} ${ex.unit}';
          buf.writeln('    • ${ex.name} — $weightStr, ${ex.reps} reps');
        }
      }

      final notes = entry.improvement.trim();
      buf.writeln(
          '  Notes: ${notes.isEmpty || notes == 'No notes' ? 'No notes' : notes}\n');
    }

    // --- Weekly averages ---
    buf.writeln('📊 WEEK AVERAGES:');
    buf.writeln(
        '  Energy: ${(totalEnergy / totalSessions).toStringAsFixed(1)} | '
        'Enjoyment: ${(totalEnjoyment / totalSessions).toStringAsFixed(1)} | '
        'Difficulty: ${(totalDifficulty / totalSessions).toStringAsFixed(1)} | '
        'Back: ${(totalBack / totalSessions).toStringAsFixed(1)}\n');

    // --- Exercise Progression vs previous week ---
    buf.writeln('📈 EXERCISE PROGRESSION (vs. previous week):');
    buf.writeln('───────────────────');

    final currentMaxes = <String, double>{};
    for (var d in currentWeekData) {
      for (var ex in d['exercises'] as List<ExerciseLog>) {
        if (!currentMaxes.containsKey(ex.name) ||
            ex.weight > currentMaxes[ex.name]!) {
          currentMaxes[ex.name] = ex.weight;
        }
      }
    }

    final prevMaxes = <String, double>{};
    for (var d in prevWeekData) {
      for (var ex in d['exercises'] as List<ExerciseLog>) {
        if (!prevMaxes.containsKey(ex.name) ||
            ex.weight > prevMaxes[ex.name]!) {
          prevMaxes[ex.name] = ex.weight;
        }
      }
    }

    if (currentMaxes.isEmpty) {
      buf.writeln('No exercises recorded this week.');
    } else {
      for (var entry in currentMaxes.entries) {
        final name = entry.key;
        final curr = entry.value;
        final weightStr =
            curr == 0 ? 'BW' : '${_formatNumber(curr)} kg';

        if (!prevMaxes.containsKey(name)) {
          buf.writeln('$name: $weightStr (new)');
        } else {
          final prev = prevMaxes[name]!;
          if (curr > prev) {
            buf.writeln('$name: $weightStr (+${_formatNumber(curr - prev)} kg)');
          } else if (curr < prev) {
            buf.writeln('$name: $weightStr (-${_formatNumber(prev - curr)} kg)');
          } else {
            buf.writeln('$name: $weightStr (no change)');
          }
        }
      }
    }

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buf.toString();
  }

  /// Format a double: show integer if whole, else 1 decimal.
  String _formatNumber(double v) {
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final dateRangeStr =
        '${DateFormat('MMM d').format(_currentWeekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';
    final currentWeekData = _entriesForWeek(_currentWeekStart);
    final sessionsCount = currentWeekData.length;
    final reportText = _generateReportText();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Weekly Report',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Week selector ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassmorphismCard(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: AppTheme.primary),
                    onPressed: _previousWeek,
                  ),
                  Column(
                    children: [
                      Text(
                        dateRangeStr,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sessionsCount sessions',
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: AppTheme.primary),
                    onPressed: _nextWeek,
                  ),
                ],
              ),
            ),
          ),

          // ── Report body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  reportText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),

          // ── Copy to Clipboard button ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reportText))
                      .then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report copied to clipboard!'),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text(
                  'Copy to Clipboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';
import 'package:metabolic/screens/edit_workout_screen.dart';
import 'package:metabolic/database/firebase_helper.dart';

class EntryDetailScreen extends StatefulWidget {
  final WorkoutEntry entry;
  final List<ExerciseLog> exercises;

  const EntryDetailScreen({
    super.key,
    required this.entry,
    required this.exercises,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late WorkoutEntry entry;
  late List<ExerciseLog> exercises;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
    exercises = widget.exercises;
  }

  Future<void> _deleteEntry(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Workout?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await DatabaseHelper().deleteEntry(entry.id!);
      FirebaseHelper().deleteWorkoutFromCloud(entry.date).catchError((e) {
        debugPrint("Firebase delete error: $e");
      });
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _editEntry(BuildContext context) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditWorkoutScreen(
          entry: entry,
          exercises: exercises,
        ),
      ),
    );
    if (edited == true && context.mounted) {
      // Reload updated data from database
      final updatedExercises = await DatabaseHelper().getExercisesForEntry(entry.id!);
      final allEntries = await DatabaseHelper().getAllEntries();
      final updatedEntry = allEntries.firstWhere((e) => e.id == entry.id);
      setState(() {
        entry = updatedEntry;
        exercises = updatedExercises;
        _hasChanges = true;
      });
    }
  }

  Widget _buildMetricRow(String emoji, String label, int value, int maxValue,
      {bool invert = false}) {
    final normalized = value / maxValue.clamp(1, 10);
    final color = AppTheme.scoreColor(normalized, invert: !invert);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value / maxValue,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            '/$maxValue',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: Text(DateFormat('EEEE, MMM d').format(entry.date)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            onPressed: () => _editEntry(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics card
            GlassmorphismCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Metrics',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow('⚡', 'Energy', entry.energy, 10),
                  _buildMetricRow('😊', 'Enjoyment', entry.enjoyment, 10),
                  _buildMetricRow('🔙', 'Back Comfort', entry.backComfort, 10,
                      invert: true),
                  _buildMetricRow('💪', 'Difficulty', entry.difficulty, 10),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Improvement card
            GlassmorphismCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      const Text(
                        'What Improved',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    entry.improvement,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Activity / Exercises details card
            if (entry.type == 'Walk' || entry.type == 'Badminton' || entry.type == 'Other')
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.type == 'Walk'
                              ? '🚶 Walk Details'
                              : entry.type == 'Badminton'
                                  ? '🏸 Badminton Details'
                                  : '🏃 Activity Details',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (entry.distance != null)
                          Column(
                            children: [
                              const Text(
                                'Distance',
                                style: TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.distance} km',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        if (entry.duration != null)
                          Column(
                            children: [
                              const Text(
                                'Duration',
                                style: TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${entry.duration} mins',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else if (exercises.isNotEmpty)
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏋️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text(
                          'Exercises (${exercises.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...exercises.asMap().entries.map((e) {
                      final idx = e.key;
                      final ex = e.value;
                      return Container(
                        margin: EdgeInsets.only(
                            bottom: idx < exercises.length - 1 ? 10 : 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                ex.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (ex.weight > 0)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${ex.weight % 1 == 0 ? ex.weight.toInt() : ex.weight}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        ex.unit,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (ex.reps > 0)
                                  Text(
                                    '${ex.reps} rep${ex.reps > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ex.weight > 0
                                          ? AppTheme.secondary
                                          : AppTheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),);
  }
}

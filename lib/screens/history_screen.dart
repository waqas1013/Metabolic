import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';
import 'package:metabolic/widgets/score_badge.dart';
import 'package:metabolic/screens/entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    _entriesFuture = DatabaseHelper().getAllEntriesWithExercises();
  }

  void refresh() {
    setState(() {
      _loadEntries();
    });
  }

  Future<void> _deleteEntry(int id) async {
    await DatabaseHelper().deleteEntry(id);
    setState(() {
      _loadEntries();
    });
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.history, size: 22, color: AppTheme.secondary),
            SizedBox(width: 8),
            Text('History'),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 80, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 20),
                  Text(
                    'No workouts logged yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by logging your first workout!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _loadEntries());
            },
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final entry = data[index]['entry'] as WorkoutEntry;
                final exercises = data[index]['exercises'] as List<ExerciseLog>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Dismissible(
                    key: ValueKey(entry.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: AppTheme.error, size: 28),
                    ),
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) => _deleteEntry(entry.id!),
                    child: GlassmorphismCard(
                      onTap: () async {
                        final deleted = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntryDetailScreen(
                              entry: entry,
                              exercises: exercises,
                            ),
                          ),
                        );
                        if (deleted == true) refresh();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.type == 'Walk'
                                      ? '🚶 Walk'
                                      : entry.type == 'Badminton'
                                          ? '🏸 Badminton'
                                          : entry.type == 'Other'
                                              ? '🏃 Cardio'
                                              : '🏋️ Strength',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('MMMM d, yyyy').format(entry.date),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Score badges row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ScoreBadge(
                                value: entry.energy,
                                maxValue: 10,
                                label: 'Energy',
                                emoji: '⚡',
                              ),
                              ScoreBadge(
                                value: entry.enjoyment,
                                maxValue: 10,
                                label: 'Enjoy',
                                emoji: '😊',
                              ),
                              ScoreBadge(
                                value: entry.backComfort,
                                maxValue: 10,
                                label: 'Back',
                                emoji: '🔙',
                                invertColors: true,
                              ),
                              ScoreBadge(
                                value: entry.difficulty,
                                maxValue: 10,
                                label: 'Diff.',
                                emoji: '💪',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Improvement preview
                          if (entry.improvement.isNotEmpty &&
                              entry.improvement != 'No notes')
                            Row(
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.improvement,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Activity details summary
                          if (entry.type == 'Walk') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🚶', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.distance ?? 0.0} km  •  ${entry.duration ?? 0} mins',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (entry.type == 'Badminton') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🏸', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.duration ?? 0} mins',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (entry.type == 'Other') ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🏃', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.distance != null ? '${entry.distance} km  •  ' : ''}${entry.duration ?? 0} mins',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (exercises.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🏋️', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 8),
                                Text(
                                  '${exercises.length} exercise${exercises.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

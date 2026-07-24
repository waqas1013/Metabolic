import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/database/firebase_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/screens/entry_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  /// Which workout types are currently selected for filtering.
  String _activeFilter = 'All';

  /// Which month-keys are expanded. Current month starts expanded.
  final Set<String> _expandedMonths = {};

  /// Whether we've done the initial expansion of the current month.
  bool _initialExpandDone = false;

  /// ScrollController for jump-to-month.
  final ScrollController _scrollController = ScrollController();

  /// Global keys for each month section so we can scroll to them.
  final Map<String, GlobalKey> _monthKeys = {};

  static const List<String> _filterLabels = [
    'All',
    'Strength',
    'Walk',
    'Badminton',
    'Other',
  ];

  static const Map<String, String> _filterEmojis = {
    'All': '📋',
    'Strength': '🏋️',
    'Walk': '🚶',
    'Badminton': '🏸',
    'Other': '🏃',
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadEntries() {
    _entriesFuture = DatabaseHelper().getAllEntriesWithExercises();
  }

  void refresh() {
    setState(() {
      _loadEntries();
    });
  }

  /// Group entries by "MMMM yyyy" month key, preserving order (newest first).
  Map<String, List<Map<String, dynamic>>> _groupByMonth(
      List<Map<String, dynamic>> data) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in data) {
      final entry = item['entry'] as WorkoutEntry;
      final key = DateFormat('MMMM yyyy').format(entry.date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  /// Filter entries by the active workout type filter.
  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> data) {
    if (_activeFilter == 'All') return data;

    // Map filter label to the workout type stored in DB
    String typeMatch;
    switch (_activeFilter) {
      case 'Strength':
        typeMatch = 'Gym';
        break;
      default:
        typeMatch = _activeFilter;
    }

    return data
        .where((item) {
          final entry = item['entry'] as WorkoutEntry;
          if (_activeFilter == 'Strength') {
            return entry.type == 'Gym' || entry.type == 'Calisthenics';
          }
          return entry.type == typeMatch;
        })
        .toList();
  }

  Future<void> _deleteEntry(WorkoutEntry entry) async {
    if (entry.id != null) {
      await DatabaseHelper().deleteEntry(entry.id!);
      FirebaseHelper().deleteWorkoutFromCloud(entry.date).catchError((e) {
        debugPrint("Firebase delete error: $e");
      });
    }
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
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showJumpToMonthSheet(List<String> monthKeys) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jump to Month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: monthKeys.length,
                  itemBuilder: (_, i) {
                    final month = monthKeys[i];
                    return ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(Icons.calendar_month,
                              size: 18, color: Colors.white),
                        ),
                      ),
                      title: Text(month,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.pop(ctx);
                        // Expand the month and scroll to it
                        setState(() {
                          _expandedMonths.add(month);
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final key = _monthKeys[month];
                          if (key?.currentContext != null) {
                            Scrollable.ensureVisible(
                              key!.currentContext!,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _workoutTypeEmoji(String type) {
    switch (type) {
      case 'Walk':
        return '🚶';
      case 'Badminton':
        return '🏸';
      case 'Other':
        return '🏃';
      default:
        return '🏋️';
    }
  }

  String _workoutTypeLabel(String type) {
    switch (type) {
      case 'Walk':
        return 'Walk';
      case 'Badminton':
        return 'Badminton';
      case 'Other':
        return 'Cardio';
      case 'Gym':
        return 'Strength';
      case 'Calisthenics':
        return 'Calisthenics';
      default:
        return type;
    }
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
      floatingActionButton: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          final filtered = _applyFilter(snapshot.data!);
          final grouped = _groupByMonth(filtered);
          return FloatingActionButton.small(
            backgroundColor: AppTheme.surface,
            onPressed: () =>
                _showJumpToMonthSheet(grouped.keys.toList()),
            child: const Icon(Icons.calendar_month,
                color: AppTheme.primary, size: 20),
          );
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final allData = snapshot.data ?? [];

          if (allData.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15)),
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

          final filtered = _applyFilter(allData);
          final grouped = _groupByMonth(filtered);
          final monthKeys = grouped.keys.toList();

          // Auto-expand current month on first load
          if (!_initialExpandDone && monthKeys.isNotEmpty) {
            _expandedMonths.add(monthKeys.first);
            _initialExpandDone = true;
          }

          // Ensure global keys exist for each month
          for (final mk in monthKeys) {
            _monthKeys.putIfAbsent(mk, () => GlobalKey());
          }

          return Column(
            children: [
              // ── Filter Chips ──
              _buildFilterChips(allData),

              // ── Month Sections ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No $_activeFilter workouts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _loadEntries());
                        },
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: monthKeys.length,
                          itemBuilder: (context, monthIndex) {
                            final monthKey = monthKeys[monthIndex];
                            final monthEntries = grouped[monthKey]!;
                            final isExpanded =
                                _expandedMonths.contains(monthKey);

                            return _buildMonthSection(
                              monthKey,
                              monthEntries,
                              isExpanded,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Filter Chips
  // ═══════════════════════════════════════════

  Widget _buildFilterChips(List<Map<String, dynamic>> allData) {
    // Count per type for badge
    final typeCounts = <String, int>{};
    for (final item in allData) {
      final entry = item['entry'] as WorkoutEntry;
      String label;
      if (entry.type == 'Gym' || entry.type == 'Calisthenics') {
        label = 'Strength';
      } else {
        label = entry.type;
      }
      typeCounts[label] = (typeCounts[label] ?? 0) + 1;
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterLabels.length,
        separatorBuilder: (_, _a) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filterLabels[index];
          final isActive = _activeFilter == label;
          final count = label == 'All'
              ? allData.length
              : (typeCounts[label] ?? 0);

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = label;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive ? AppTheme.primaryGradient : null,
                color: isActive
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_filterEmojis[label]} $label',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Month Section (header + entries)
  // ═══════════════════════════════════════════

  Widget _buildMonthSection(
    String monthKey,
    List<Map<String, dynamic>> entries,
    bool isExpanded,
  ) {
    // Find dominant type for the month
    final typeCounts = <String, int>{};
    for (final item in entries) {
      final e = item['entry'] as WorkoutEntry;
      final label = _workoutTypeLabel(e.type);
      typeCounts[label] = (typeCounts[label] ?? 0) + 1;
    }
    final dominantType = typeCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return Column(
      key: _monthKeys[monthKey],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Month Header ──
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMonths.remove(monthKey);
              } else {
                _expandedMonths.add(monthKey);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, top: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withValues(alpha: 0.15),
                  AppTheme.accent.withValues(alpha: 0.08),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entries.length} workout${entries.length != 1 ? 's' : ''} · Mostly $dominantType',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Entries (animated expand/collapse) ──
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: entries.map((item) {
              final entry = item['entry'] as WorkoutEntry;
              final exercises =
                  item['exercises'] as List<ExerciseLog>;
              return _buildCompactWorkoutCard(entry, exercises);
            }).toList(),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
          sizeCurve: Curves.easeInOut,
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // Compact Workout Card
  // ═══════════════════════════════════════════

  Widget _buildCompactWorkoutCard(
      WorkoutEntry entry, List<ExerciseLog> exercises) {
    final emoji = _workoutTypeEmoji(entry.type);
    final typeLabel = _workoutTypeLabel(entry.type);

    // Build summary text
    String summary;
    if (entry.type == 'Walk') {
      final parts = <String>[];
      if (entry.distance != null) parts.add('${entry.distance} km');
      if (entry.duration != null) parts.add('${entry.duration} min');
      summary = parts.isNotEmpty ? parts.join(' · ') : 'Walk';
    } else if (entry.type == 'Badminton') {
      summary = entry.duration != null ? '${entry.duration} min' : 'Badminton';
    } else if (entry.type == 'Other') {
      final parts = <String>[];
      if (entry.distance != null) parts.add('${entry.distance} km');
      if (entry.duration != null) parts.add('${entry.duration} min');
      summary = parts.isNotEmpty ? parts.join(' · ') : 'Activity';
    } else {
      summary = exercises.isNotEmpty
          ? '${exercises.length} exercise${exercises.length > 1 ? 's' : ''}'
          : 'Strength';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline,
              color: AppTheme.error, size: 28),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => _deleteEntry(entry),
        child: GestureDetector(
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EntryDetailScreen(
                  entry: entry,
                  exercises: exercises,
                ),
              ),
            );
            if (changed == true) refresh();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              children: [
                // ── Row 1: Type badge + date + summary + chevron ──
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$emoji $typeLabel',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Date
                    Text(
                      DateFormat('EEE, MMM d').format(entry.date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Summary
                    Text(
                      summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 18),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Row 2: Compact inline score badges ──
                Row(
                  children: [
                    _buildMiniScore('⚡', entry.energy, 10),
                    const SizedBox(width: 12),
                    _buildMiniScore('😊', entry.enjoyment, 10),
                    const SizedBox(width: 12),
                    _buildMiniScore('🔙', entry.backComfort, 10,
                        invert: true),
                    const SizedBox(width: 12),
                    _buildMiniScore('💪', entry.difficulty, 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Mini Score (inline, compact)
  // ═══════════════════════════════════════════

  Widget _buildMiniScore(String emoji, int value, int maxValue,
      {bool invert = false}) {
    final normalized = value / maxValue.clamp(1, 10);
    final color = AppTheme.scoreColor(normalized, invert: !invert);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

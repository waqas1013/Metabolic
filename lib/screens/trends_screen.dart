import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => TrendsScreenState();
}

class TrendsScreenState extends State<TrendsScreen> {
  String _selectedRange = 'All';
  String _selectedTypeFilter = 'All';
  List<WorkoutEntry> _entries = [];
  List<String> _exerciseNames = [];
  String? _selectedExercise;
  List<Map<String, dynamic>> _weightData = [];
  bool _isLoading = true;
  bool _showReps = false;

  final _ranges = ['1W', '1M', '3M', '6M', 'All'];
  final _types = ['All', 'Gym', 'Walk', 'Badminton'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper();
    final allData = await db.getAllEntriesWithExercises();
    final names = await db.getDistinctExerciseNames();

    final entries = allData
        .map((d) => d['entry'] as WorkoutEntry)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Filter by date range
    final now = DateTime.now();
    DateTime? cutoff;
    switch (_selectedRange) {
      case '1W':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':
        cutoff = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':
        cutoff = DateTime(now.year, now.month - 6, now.day);
        break;
    }

    var filtered = cutoff != null
        ? entries.where((e) => e.date.isAfter(cutoff!)).toList()
        : entries;

    // Filter by activity type
    if (_selectedTypeFilter != 'All') {
      filtered = filtered.where((e) => e.type == _selectedTypeFilter).toList();
    }

    List<Map<String, dynamic>> weightData = [];
    final exercise = _selectedExercise ?? (names.isNotEmpty ? names.first : null);
    if (exercise != null) {
      weightData = await db.getWeightProgressionForExercise(exercise);
      if (cutoff != null) {
        weightData = weightData.where((w) {
          final date = DateTime.parse(w['date'] as String);
          return date.isAfter(cutoff!);
        }).toList();
      }
    }

    setState(() {
      _entries = filtered;
      _exerciseNames = names;
      _selectedExercise = exercise;
      _weightData = weightData;
      _isLoading = false;
    });
  }

  List<FlSpot> _spotsFor(List<WorkoutEntry> entries, int Function(WorkoutEntry) getValue) {
    if (entries.isEmpty) return [];
    final firstDate = entries.first.date;
    return entries.asMap().entries.map((e) {
      final daysDiff = e.value.date.difference(firstDate).inDays.toDouble();
      return FlSpot(daysDiff, getValue(e.value).toDouble());
    }).toList();
  }

  Widget _buildLegend() {
    final items = [
      ('Energy', AppTheme.primary),
      ('Enjoyment', AppTheme.secondary),
      ('Back', AppTheme.error),
      ('Difficulty', AppTheme.warning),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.$2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                item.$1,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _dateLabel(double daysDiff) {
    if (_entries.isEmpty) return '';
    final date = _entries.first.date.add(Duration(days: daysDiff.toInt()));
    return DateFormat('M/d').format(date);
  }

  Widget _buildMetricsChart() {
    if (_entries.length < 2) {
      return _buildEmptyChart('Log at least 2 workouts to see trends');
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _entries.length > 7
                        ? (_entries.last.date.difference(_entries.first.date).inDays / 5)
                            .ceilToDouble()
                            .clamp(1, double.infinity)
                        : 1,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _dateLabel(value),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 2,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 10,
              lineBarsData: [
                _lineData(_spotsFor(_entries, (e) => e.energy), AppTheme.primary),
                _lineData(_spotsFor(_entries, (e) => e.enjoyment), AppTheme.secondary),
                _lineData(_spotsFor(_entries, (e) => e.backComfort), AppTheme.error),
                _lineData(_spotsFor(_entries, (e) => e.difficulty), AppTheme.warning),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.surface.withValues(alpha: 0.9),
                  tooltipRoundedRadius: 12,
                  getTooltipItems: (spots) => spots.map((spot) {
                    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.error, AppTheme.warning];
                    final labels = ['Energy', 'Enjoy', 'Back', 'Diff'];
                    return LineTooltipItem(
                      '${labels[spot.barIndex]}: ${spot.y.toInt()}',
                      TextStyle(color: colors[spot.barIndex], fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: spots.length < 15,
        getDotPainter: (spot, meta, chartData, barIndex) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildBackComfortChart() {
    if (_entries.length < 2) {
      return _buildEmptyChart('Need more data for back comfort trend');
    }

    final spots = _spotsFor(_entries, (e) => e.backComfort);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2,
            getDrawingHorizontalLine: (value) => FlLine(
              color: value == 5
                  ? AppTheme.warning.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              strokeWidth: value == 5 ? 2 : 1,
              dashArray: value == 5 ? [5, 5] : null,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: _entries.length > 7
                    ? (_entries.last.date.difference(_entries.first.date).inDays / 5)
                        .ceilToDouble()
                        .clamp(1, double.infinity)
                    : 1,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _dateLabel(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 2,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 10,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.error,
              barWidth: 3,
              dotData: FlDotData(
                show: spots.length < 15,
                getDotPainter: (spot, meta, chartData, barIndex) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.error,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.error.withValues(alpha: 0.2),
                    AppTheme.error.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightData.length < 2) {
      return _buildEmptyChart('Log more exercises to see progression');
    }

    final firstDate = DateTime.parse(_weightData.first['date'] as String);
    final spots = _weightData.asMap().entries.map((e) {
      final date = DateTime.parse(e.value['date'] as String);
      final daysDiff = date.difference(firstDate).inDays.toDouble();
      final val = _showReps
          ? (e.value['reps'] as num? ?? 0).toDouble()
          : (e.value['weight'] as num? ?? 0).toDouble();
      return FlSpot(daysDiff, val);
    }).toList();

    if (spots.isEmpty) {
      return _buildEmptyChart('No progression data');
    }

    final maxVal = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minVal = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(5.0, double.infinity);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final date = firstDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: (minVal - range * 0.1).floorToDouble().clamp(0, double.infinity),
          maxY: (maxVal + range * 0.1).ceilToDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: AppTheme.primaryGradient,
              barWidth: 3,
              dotData: FlDotData(
                show: spots.length < 20,
                getDotPainter: (spot, meta, chartData, barIndex) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.01),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.trending_up, size: 22, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time range selector
                  Row(
                    children: [
                      const Text(
                        'Range:  ',
                        style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _ranges.map((range) {
                              final selected = range == _selectedRange;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(range),
                                  selected: selected,
                                  selectedColor: AppTheme.primary,
                                  backgroundColor: AppTheme.surface,
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide.none,
                                  onSelected: (_) {
                                    setState(() => _selectedRange = range);
                                    _loadData();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Activity type selector
                  Row(
                    children: [
                      const Text(
                        'Activity: ',
                        style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _types.map((type) {
                              final selected = type == _selectedTypeFilter;
                              final display = type == 'Gym'
                                  ? '🏋️ Gym'
                                  : type == 'Walk'
                                      ? '🚶 Walk'
                                      : type == 'Badminton'
                                          ? '🏸 Badminton'
                                          : 'All';
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(display),
                                  selected: selected,
                                  selectedColor: AppTheme.secondary,
                                  backgroundColor: AppTheme.surface,
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: BorderSide.none,
                                  onSelected: (_) {
                                    setState(() => _selectedTypeFilter = type);
                                    _loadData();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Metrics chart
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊  Metrics Over Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildMetricsChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Back comfort chart
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🔙  Back Comfort Trend',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Warning > 5',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildBackComfortChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Exercise progression chart
                  GlassmorphismCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '📈  Exercise Progression',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (_exerciseNames.isNotEmpty)
                              Row(
                                children: [
                                  Text(
                                    'Reps',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _showReps ? AppTheme.primary : Colors.white54,
                                      fontWeight: _showReps ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: _showReps,
                                    activeThumbColor: AppTheme.primary,
                                    activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                                    onChanged: (v) {
                                      setState(() => _showReps = v);
                                      _loadData();
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (_exerciseNames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedExercise,
                                dropdownColor: AppTheme.surface,
                                isExpanded: true,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Colors.white54),
                                items: _exerciseNames.map((name) {
                                  return DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  setState(() => _selectedExercise = v);
                                  _loadData();
                                },
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildWeightChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

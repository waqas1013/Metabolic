import 'package:flutter/material.dart';
import 'package:metabolic/database/database_helper.dart';
import 'package:metabolic/database/firebase_helper.dart';
import 'package:metabolic/models/workout_entry.dart';
import 'package:metabolic/theme/app_theme.dart';
import 'package:metabolic/widgets/glassmorphism_card.dart';
import 'package:metabolic/widgets/metric_slider.dart';
import 'package:metabolic/widgets/exercise_input_card.dart';

class EditWorkoutScreen extends StatefulWidget {
  final WorkoutEntry entry;
  final List<ExerciseLog> exercises;

  const EditWorkoutScreen({
    super.key,
    required this.entry,
    required this.exercises,
  });

  @override
  State<EditWorkoutScreen> createState() => _EditWorkoutScreenState();
}

class _EditWorkoutScreenState extends State<EditWorkoutScreen> {
  late int _energy;
  late int _enjoyment;
  late int _backComfort;
  late int _difficulty;
  late String _selectedType;
  late TextEditingController _improvementController;
  late TextEditingController _distanceController;
  late TextEditingController _durationController;

  final List<TextEditingController> _exerciseNameControllers = [];
  final List<TextEditingController> _exerciseWeightControllers = [];
  final List<TextEditingController> _exerciseRepsControllers = [];
  final List<String> _exerciseUnits = [];

  bool _isSaving = false;
  List<String> _exerciseSuggestions = [];

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _energy = e.energy;
    _enjoyment = e.enjoyment;
    _backComfort = e.backComfort;
    _difficulty = e.difficulty;
    _selectedType = e.type;
    _improvementController = TextEditingController(
      text: e.improvement == 'No notes' ? '' : e.improvement,
    );
    _distanceController = TextEditingController(
      text: e.distance?.toString() ?? '10.0',
    );
    _durationController = TextEditingController(
      text: e.duration?.toString() ?? '60',
    );

    // Pre-populate exercise rows
    if (widget.exercises.isNotEmpty) {
      for (final ex in widget.exercises) {
        _exerciseNameControllers.add(TextEditingController(text: ex.name));
        _exerciseWeightControllers.add(
          TextEditingController(text: ex.weight > 0 ? ex.weight.toString() : ''),
        );
        _exerciseRepsControllers.add(
          TextEditingController(text: ex.reps > 0 ? ex.reps.toString() : ''),
        );
        _exerciseUnits.add(ex.unit);
      }
    } else {
      _addExercise();
    }

    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final list = await DatabaseHelper().getExerciseLibrary();
    setState(() => _exerciseSuggestions = list);
  }

  @override
  void dispose() {
    _improvementController.dispose();
    _distanceController.dispose();
    _durationController.dispose();
    for (final c in _exerciseNameControllers) {
      c.dispose();
    }
    for (final c in _exerciseWeightControllers) {
      c.dispose();
    }
    for (final c in _exerciseRepsControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    setState(() {
      _exerciseNameControllers.add(TextEditingController());
      _exerciseWeightControllers.add(TextEditingController());
      _exerciseRepsControllers.add(TextEditingController());
      _exerciseUnits.add('kg');
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exerciseNameControllers[index].dispose();
      _exerciseWeightControllers[index].dispose();
      _exerciseRepsControllers[index].dispose();
      _exerciseNameControllers.removeAt(index);
      _exerciseWeightControllers.removeAt(index);
      _exerciseRepsControllers.removeAt(index);
      _exerciseUnits.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      double? distance;
      int? duration;
      final exercises = <ExerciseLog>[];

      if (_selectedType == 'Walk') {
        distance = double.tryParse(_distanceController.text) ?? 10.0;
        duration = int.tryParse(_durationController.text) ?? 60;
      } else if (_selectedType == 'Badminton') {
        duration = int.tryParse(_durationController.text) ?? 60;
      } else if (_selectedType == 'Other') {
        distance = double.tryParse(_distanceController.text);
        duration = int.tryParse(_durationController.text);
      } else {
        for (int i = 0; i < _exerciseNameControllers.length; i++) {
          final name = _exerciseNameControllers[i].text.trim();
          final weightText = _exerciseWeightControllers[i].text.trim();
          final repsText = _exerciseRepsControllers[i].text.trim();
          if (name.isNotEmpty && (weightText.isNotEmpty || repsText.isNotEmpty)) {
            exercises.add(ExerciseLog(
              name: name,
              weight: double.tryParse(weightText) ?? 0,
              unit: _exerciseUnits[i],
              reps: int.tryParse(repsText) ?? 0,
            ));
          }
        }
      }

      final updatedEntry = widget.entry.copyWith(
        energy: _energy,
        enjoyment: _enjoyment,
        backComfort: _backComfort,
        difficulty: _difficulty,
        improvement: _improvementController.text.trim().isEmpty
            ? 'No notes'
            : _improvementController.text.trim(),
        type: _selectedType,
        distance: distance,
        duration: duration,
      );

      await DatabaseHelper().updateEntry(updatedEntry, exercises);
      FirebaseHelper().syncSingleWorkout(updatedEntry, exercises).catchError((e) {
        debugPrint("Firebase sync error: $e");
      });

      if (mounted) {
        Navigator.pop(context, true); // true = was edited
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTypeChip(String type, String emoji) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Workout'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check, color: AppTheme.success),
            label: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Type selector
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTypeChip('Gym', '🏋️'),
                      _buildTypeChip('Walk', '🚶'),
                      _buildTypeChip('Badminton', '🏸'),
                      _buildTypeChip('Other', '🏃'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metric sliders
            MetricSlider(
              label: 'Energy Before Workout',
              value: _energy,
              min: 1,
              max: 10,
              emoji: '⚡',
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _energy = v),
            ),
            MetricSlider(
              label: 'Enjoyment',
              value: _enjoyment,
              min: 1,
              max: 10,
              emoji: '😊',
              activeColor: AppTheme.secondary,
              onChanged: (v) => setState(() => _enjoyment = v),
            ),
            MetricSlider(
              label: 'Back Comfort',
              value: _backComfort,
              min: 0,
              max: 10,
              emoji: '🔙',
              invertColors: true,
              subtitle: '0 = No issues  •  10 = Severe pain',
              activeColor: _backComfort > 5 ? AppTheme.error : AppTheme.success,
              onChanged: (v) => setState(() => _backComfort = v),
            ),
            MetricSlider(
              label: 'Difficulty',
              value: _difficulty,
              min: 1,
              max: 10,
              emoji: '💪',
              activeColor: AppTheme.warning,
              onChanged: (v) => setState(() => _difficulty = v),
            ),

            const SizedBox(height: 16),

            // Improvement text
            GlassmorphismCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text(
                        'One thing that improved today',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _improvementController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Better form on pull-ups, deeper squats...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cardio fields or Exercise list
            if (_selectedType == 'Walk' || _selectedType == 'Badminton' || _selectedType == 'Other') ...[
              GlassmorphismCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedType == 'Walk'
                              ? '🚶 Walk Details'
                              : _selectedType == 'Badminton'
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
                      children: [
                        if (_selectedType == 'Walk' || _selectedType == 'Other') ...[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distance (km)',
                                  style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _distanceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.04),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppTheme.primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Duration (mins)',
                                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(alpha: 0.04),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppTheme.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Text('🏋️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Text(
                    'Exercises & Weights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _addExercise,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Add',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_exerciseNameControllers.length, (i) {
                return ExerciseInputCard(
                  index: i,
                  nameController: _exerciseNameControllers[i],
                  weightController: _exerciseWeightControllers[i],
                  repsController: _exerciseRepsControllers[i],
                  unit: _exerciseUnits[i],
                  onUnitChanged: (u) => setState(() => _exerciseUnits[i] = u),
                  onRemove: () => _removeExercise(i),
                  suggestions: _exerciseSuggestions,
                );
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

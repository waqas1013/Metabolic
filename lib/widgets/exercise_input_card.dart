import 'package:flutter/material.dart';
import 'package:metabolic/theme/app_theme.dart';

class ExerciseInputCard extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final String unit;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onRemove;
  final List<String> suggestions;

  const ExerciseInputCard({
    super.key,
    required this.index,
    required this.nameController,
    required this.weightController,
    required this.repsController,
    required this.unit,
    required this.onUnitChanged,
    required this.onRemove,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: AppTheme.glassmorphismDecorationSubtle,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return suggestions.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                nameController.text = selection;
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                // Sync the controller with the parent nameController
                if (textEditingController.text != nameController.text) {
                  textEditingController.text = nameController.text;
                }
                textEditingController.addListener(() {
                  nameController.text = textEditingController.text;
                });
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (_) => onFieldSubmitted(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Exercise',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: index < options.length - 1
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 45,
            child: TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Wt',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: unit,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                ],
                onChanged: (v) => onUnitChanged(v ?? 'kg'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 45,
            child: TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Reps',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: AppTheme.error, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

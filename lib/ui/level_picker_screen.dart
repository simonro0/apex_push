import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/training_data.dart';
import '../models/workout.dart';

class LevelPickerScreen extends StatefulWidget {
  final ActiveProgram current;

  const LevelPickerScreen({super.key, required this.current});

  @override
  State<LevelPickerScreen> createState() => _LevelPickerScreenState();
}

class _LevelPickerScreenState extends State<LevelPickerScreen> {
  late String _selectedUnit;
  late String _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedUnit       = widget.current.unitId;
    _selectedDifficulty = widget.current.difficulty;
  }

  /// Show levels 1 through at least 8, plus 2 ahead of the current level.
  int get _levelCount {
    final currentLevel =
        int.tryParse(widget.current.unitId.split('-').first) ?? 1;
    return (currentLevel + 2).clamp(8, 20);
  }

  void _select(String unitId, String difficulty) {
    setState(() {
      _selectedUnit       = unitId;
      _selectedDifficulty = difficulty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('select_level'))),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _levelCount,
        itemBuilder: (ctx, levelIdx) {
          final level = levelIdx + 1;
          return _LevelSection(
            level:              level,
            selectedUnit:       _selectedUnit,
            selectedDifficulty: _selectedDifficulty,
            onSelect:           _select,
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            onPressed: () => Navigator.pop(
              context,
              ActiveProgram(
                  unitId: _selectedUnit, difficulty: _selectedDifficulty),
            ),
            child: Text(
              context.t('apply'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Level section ─────────────────────────────────────────────────────────────

class _LevelSection extends StatelessWidget {
  final int    level;
  final String selectedUnit;
  final String selectedDifficulty;
  final void Function(String unitId, String difficulty) onSelect;

  const _LevelSection({
    required this.level,
    required this.selectedUnit,
    required this.selectedDifficulty,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final units = ['$level-1', '$level-2', '$level-3'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            context.tp('level_n', {'n': '$level'}),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...units.map(
          (uid) => _UnitRow(
            unitId:             uid,
            isSelectedUnit:     uid == selectedUnit,
            selectedDifficulty: selectedDifficulty,
            onSelect:           onSelect,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// ── Unit row ──────────────────────────────────────────────────────────────────

class _UnitRow extends StatelessWidget {
  final String unitId;
  final bool   isSelectedUnit;
  final String selectedDifficulty;
  final void Function(String unitId, String difficulty) onSelect;

  const _UnitRow({
    required this.unitId,
    required this.isSelectedUnit,
    required this.selectedDifficulty,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              unitId,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight:
                    isSelectedUnit ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: TrainingData.difficulties.map((diff) {
                final selected = isSelectedUnit && diff == selectedDifficulty;
                final reps     = TrainingData.getReps(unitId, diff);
                final label    = '${_shortDiff(diff)}: ${reps.join('-')}';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _DiffChip(
                      label:    label,
                      selected: selected,
                      color:    _diffColor(diff),
                      onTap:    () => onSelect(unitId, diff),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortDiff(String d) => d.substring(0, 1);

  static Color _diffColor(String d) => switch (d) {
        'Easy'   => Colors.green,
        'Normal' => Colors.orange,
        'Hard'   => Colors.red,
        _        => Colors.grey,
      };
}

// ── Difficulty chip ───────────────────────────────────────────────────────────

class _DiffChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _DiffChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color:        selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border:       Border.all(
              color: selected ? color : Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   11,
            color:      selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

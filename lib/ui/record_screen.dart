import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/workout.dart';
import 'session_detail_screen.dart';
import 'widgets/monthly_combo_chart.dart';

class RecordScreen extends StatefulWidget {
  final List<Workout> history;

  const RecordScreen({super.key, required this.history});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late DateTime _month;
  bool _showCalories = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  // ── Data helpers ───────────────────────────────────────────────────────────

  Map<int, int> _dailyReps(int year, int month) {
    final map = <int, int>{};
    for (final w in widget.history) {
      if (w.date.year == year && w.date.month == month) {
        map[w.date.day] = (map[w.date.day] ?? 0) + w.count;
      }
    }
    return map;
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  String _monthLabel(DateTime d) => context.formatMonth(d);

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _prevMonth() => setState(
      () => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime.now())) {
      setState(() => _month = next);
    }
  }

  // ── Chart builders ─────────────────────────────────────────────────────────

  List<BarChartGroupData> _buildBarGroups(
      Map<int, int> data, int days, double Function(int) value, double barWidth) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return List.generate(days, (i) {
      final day = i + 1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY:          value(data[day] ?? 0),
            color:        (data[day] ?? 0) > 0
                ? primaryColor
                : primaryColor.withValues(alpha: 0.08),
            width:        barWidth,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    });
  }

  List<FlSpot> _buildSpots(Map<int, int> data, double Function(int) value) {
    return data.entries
        .where((e) => e.value > 0)
        .map((e) => FlSpot((e.key - 1).toDouble(), value(e.value)))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  // ── Tap handler ────────────────────────────────────────────────────────────

  void _onBarTap(int x) {
    final day = x + 1;
    final sessions = widget.history.where((w) =>
        w.date.year == _month.year &&
        w.date.month == _month.month &&
        w.date.day == day).toList();
    if (sessions.isEmpty) return;

    if (sessions.length == 1) {
      _openSession(sessions.first);
    } else {
      _showSessionPicker(sessions);
    }
  }

  void _openSession(Workout w) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailScreen(workout: w)),
    );
  }

  String _sessionSubtitle(BuildContext ctx, Workout w) {
    final reps = '${w.count} ${ctx.t('reps_short')}';
    final h    = w.date.hour.toString().padLeft(2, '0');
    final m    = w.date.minute.toString().padLeft(2, '0');
    // puud imports have no time; don't show a misleading 00:00.
    if (w.date.hour == 0 && w.date.minute == 0 && w.date.second == 0) {
      return reps;
    }
    return '$reps · $h:$m';
  }

  void _showSessionPicker(List<Workout> sessions) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.t('select_session'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...sessions.map((w) {
              final label = w.isFreeTraining
                  ? context.t('free_training_label')
                  : '${w.levelId} – ${w.difficulty}';
              return ListTile(
                leading: Icon(Icons.fitness_center,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(label),
                subtitle: Text(_sessionSubtitle(context, w)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _openSession(w);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final year  = _month.year;
    final month = _month.month;
    final days  = _daysInMonth(year, month);
    final data  = _dailyReps(year, month);

    double valueFor(int reps) =>
        _showCalories ? reps * 0.5 : reps.toDouble();

    final maxVal = data.values.isEmpty
        ? 10.0
        : data.values
            .map(valueFor)
            .reduce((a, b) => a > b ? a : b) * 1.15;

    final spots = _buildSpots(data, valueFor);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('record'))),
      body: Column(
        children: [
          // ── Month navigation ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                ),
                Text(
                  _monthLabel(_month),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          // ── Pushups / Calorie tabs ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _TabChip(
                  label:    context.t('pushups_tab'),
                  selected: !_showCalories,
                  onTap:    () => setState(() => _showCalories = false),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label:    context.t('calories_tab'),
                  selected: _showCalories,
                  onTap:    () => setState(() => _showCalories = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Chart ─────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: LayoutBuilder(builder: (context, constraints) {
                const leftReserved = 40.0;
                final bw = ((constraints.maxWidth - leftReserved) / days * 0.5)
                    .clamp(1.0, 7.0);
                final barGroups = _buildBarGroups(data, days, valueFor, bw);
                return MonthlyComboChart(
                  barGroups:  barGroups,
                  spots:      spots,
                  days:       days,
                  maxY:       maxVal,
                  onBarTap:   _onBarTap,
                  yAxisLabel: _showCalories ? 'kcal' : '',
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          // ── Home button ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(context.t('home')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color:        selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: selected ? primary : scheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize:   13,
          ),
        ),
      ),
    );
  }
}

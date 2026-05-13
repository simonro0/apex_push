import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/settings_provider.dart';
import '../models/workout.dart';

class SessionDetailScreen extends StatelessWidget {
  final Workout   workout;
  final List<int> splits;
  final List<int> targetReps;

  const SessionDetailScreen({
    super.key,
    required this.workout,
    this.splits     = const [],
    this.targetReps = const [],
  });

  @override
  Widget build(BuildContext context) {
    final calories = (workout.count * 0.5).round();
    final mins     = workout.durationSeconds ~/ 60;
    final secs     = workout.durationSeconds % 60;
    final locale   = context.watch<SettingsProvider>().locale;

    final levelStr = workout.levelId != null
        ? '${workout.levelId} (${workout.difficulty})'
        : context.t('free_training_label');

    return Scaffold(
      appBar: AppBar(title: Text(context.t('training_completed'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(
            dateStr:   AppLocalizations.formatDate(workout.date, locale),
            level:     levelStr,
            totalReps: workout.count,
            duration:  context.tp('min_sec', {
              'min': '$mins',
              'sec': secs.toString().padLeft(2, '0'),
            }),
            calories:  context.tp('kcal_approx', {'n': '$calories'}),
          ),
          if (splits.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              context.t('sets_section'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(splits.length, (i) {
              final target  = i < targetReps.length ? targetReps[i] : null;
              final reached = splits[i];
              final ok      = target == null || reached >= target;
              return _SetRow(
                label:   context.tp('set_n', {'n': '${i + 1}'}),
                target:  target != null
                    ? context.tp('target_label', {'n': '$target'})
                    : null,
                reached: context.tp('reached_label', {'n': '$reached'}),
                ok:      ok,
              );
            }),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.t('continue_upper'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String dateStr;
  final String level;
  final int    totalReps;
  final String duration;
  final String calories;

  const _SummaryCard({
    required this.dateStr,
    required this.level,
    required this.totalReps,
    required this.duration,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(icon: Icons.calendar_today,       label: context.t('date_label'),     value: dateStr),
            _Row(icon: Icons.fitness_center,        label: context.t('level_label'),    value: level),
            _Row(icon: Icons.repeat,                label: context.t('total_label'),    value: '$totalReps ${context.t('reps_unit')}'),
            _Row(icon: Icons.timer_outlined,        label: context.t('duration_label'), value: duration),
            _Row(icon: Icons.local_fire_department, label: context.t('calories_label'), value: calories),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text('$label:', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Set row ───────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final String  label;
  final String? target;
  final String  reached;
  final bool    ok;

  const _SetRow({
    required this.label,
    required this.target,
    required this.reached,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          if (target != null) ...[
            Text(target!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
            const Text('|', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
          ],
          Text(
            reached,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ok ? Colors.green : Colors.orange,
            ),
          ),
          const Spacer(),
          Icon(
            ok ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 18,
            color: ok ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/workout.dart';

/// Shown immediately after completing a structured workout, and reachable from
/// the Record screen for historical sessions.
///
/// [splits] and [targetReps] are only available for the post-training flow;
/// they are null/empty for historical views (per-set data is not persisted yet).
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

    return Scaffold(
      appBar: AppBar(title: const Text('Training abgeschlossen')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(
            date:     workout.date,
            level:    workout.levelId != null
                ? '${workout.levelId} (${workout.difficulty})'
                : 'Freies Training',
            totalReps: workout.count,
            duration:  '$mins min ${secs.toString().padLeft(2, '0')} s',
            calories:  '≈ $calories kcal',
          ),
          if (splits.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Sätze',
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
                setNumber: i + 1,
                target:   target,
                reached:  reached,
                ok:       ok,
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
            child: const Text('WEITER', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final DateTime date;
  final String   level;
  final int      totalReps;
  final String   duration;
  final String   calories;

  const _SummaryCard({
    required this.date,
    required this.level,
    required this.totalReps,
    required this.duration,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(icon: Icons.calendar_today, label: 'Datum',    value: dateStr),
            _Row(icon: Icons.fitness_center,  label: 'Level',    value: level),
            _Row(icon: Icons.repeat,          label: 'Gesamt',   value: '$totalReps Wdh.'),
            _Row(icon: Icons.timer_outlined,  label: 'Dauer',    value: duration),
            _Row(icon: Icons.local_fire_department, label: 'Kalorien', value: calories),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const months   = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    final wd = weekdays[d.weekday - 1];
    final mo = months[d.month - 1];
    return '$wd, ${d.day}. $mo ${d.year}';
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
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Set row ───────────────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int  setNumber;
  final int? target;
  final int  reached;
  final bool ok;

  const _SetRow({
    required this.setNumber,
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
            child: Text(
              'Satz $setNumber',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (target != null) ...[
            Text('Ziel: $target', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
            const Text('|', style: TextStyle(color: Colors.grey)),
            const SizedBox(width: 10),
          ],
          Text(
            'Erreicht: $reached',
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

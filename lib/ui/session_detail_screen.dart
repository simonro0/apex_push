import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/settings_provider.dart';
import '../models/workout.dart';

// Weekday abbreviations used by _WeeklyCard.
const _weekdaysDe = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _weekdaysEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class SessionDetailScreen extends StatelessWidget {
  final Workout        workout;
  final List<int>      splits;
  final List<int>      targetReps;
  final int?           verifiedReps;
  final List<Workout>? history;

  const SessionDetailScreen({
    super.key,
    required this.workout,
    this.splits       = const [],
    this.targetReps   = const [],
    this.verifiedReps,
    this.history,
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
            dateStr:      AppLocalizations.formatDate(workout.date, locale),
            level:        levelStr,
            totalReps:    workout.count,
            duration:     context.tp('min_sec', {
              'min': '$mins',
              'sec': secs.toString().padLeft(2, '0'),
            }),
            calories:     context.tp('kcal_approx', {'n': '$calories'}),
            verifiedReps: verifiedReps,
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
          if (history != null) ...[
            const SizedBox(height: 20),
            _WeeklyCard(history: history!, baseDate: workout.date),
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
  final int?   verifiedReps;

  const _SummaryCard({
    required this.dateStr,
    required this.level,
    required this.totalReps,
    required this.duration,
    required this.calories,
    this.verifiedReps,
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
            if (verifiedReps != null)
              _Row(
                icon:  Icons.sensors,
                label: context.t('sensor_verified'),
                value: '$verifiedReps / $totalReps',
              ),
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

// ── Weekly overview card ──────────────────────────────────────────────────────

class _WeeklyCard extends StatelessWidget {
  final List<Workout> history;
  final DateTime      baseDate;

  const _WeeklyCard({required this.history, required this.baseDate});

  @override
  Widget build(BuildContext context) {
    final today  = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // Aggregate reps by day-of-week offset (0 = Monday)
    final daily = <int, int>{};
    for (final w in history) {
      final d    = DateTime(w.date.year, w.date.month, w.date.day);
      final diff = d.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        daily[diff] = (daily[diff] ?? 0) + w.count;
      }
    }
    final weekTotal  = daily.values.fold(0, (s, v) => s + v);
    final todayOffset = today.difference(monday).inDays;

    final locale = context.watch<SettingsProvider>().locale;
    final labels = locale == 'de' ? _weekdaysDe : _weekdaysEn;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('week_overview'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  context.tp('week_total', {'n': '$weekTotal'}),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final reps    = daily[i] ?? 0;
                final trained = reps > 0;
                final isToday = i == todayOffset;

                return Column(
                  children: [
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? primary : Colors.grey,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: trained
                            ? primary.withValues(alpha: 0.85)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: primary, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: trained
                          ? Text(
                              _compact(reps),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static String _compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

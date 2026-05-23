import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../logic/settings_provider.dart';
import '../logic/share_service.dart';
import '../models/rep_detail.dart';
import '../models/training_data.dart';
import '../models/workout.dart';
import 'widgets/share_card.dart';

class SessionDetailScreen extends StatefulWidget {
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
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  List<RepDetail> _repDetails          = [];
  List<int>       _reconstructedSplits  = [];
  List<int>       _reconstructedTargets = [];

  final _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadRepDetails();
  }

  String _levelStr(BuildContext ctx) => switch (
        (widget.workout.levelId, widget.workout.difficulty)) {
    (final id?, final diff?) => '$id ($diff)',
    (final id?, null)        => id,
    _ when !widget.workout.isFreeTraining =>
      ctx.tr('structured_training_label'),
    _                        => ctx.tr('free_training_label'),
  };

  void _showShareSheet(BuildContext ctx, List<int> effectiveSplits) {
    final locale = ctx.read<SettingsProvider>().locale;
    final date   = AppLocalizations.formatDate(widget.workout.date, locale);

    // Sub-label: "Freies Training" for free sessions, splits for structured.
    final subLabel = widget.workout.isFreeTraining
        ? AppLocalizations.translate('free_training_label', locale)
        : (effectiveSplits.isEmpty ? null : effectiveSplits.join(' · '));

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: const Color(0xFF0E0E1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, 16 + MediaQuery.of(sheetCtx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctx.t('share_workout'),
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Card preview + RepaintBoundary for screenshot capture.
              RepaintBoundary(
                key: _shareCardKey,
                child: ShareCard(
                  workout:       widget.workout,
                  formattedDate: date,
                  subLabel:      subLabel,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6DFF),
                    foregroundColor: Colors.white,
                    padding:         const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon:    const Icon(Icons.share_outlined),
                  label:   Text(ctx.t('share_btn')),
                  onPressed: () async {
                    // Capture while the card is still in the widget tree,
                    // then close the sheet before opening the share dialog.
                    await ShareService.captureAndShare(_shareCardKey);
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadRepDetails() async {
    final id = widget.workout.id;
    if (id == null) return;
    final details = await DatabaseHelper.instance.getRepDetailsForWorkout(id);

    List<int> reconstructedSplits  = [];
    List<int> reconstructedTargets = [];

    if (widget.splits.isEmpty && details.isNotEmpty) {
      // Group reps by set_index to reconstruct per-set counts.
      final setMap = <int, int>{};
      for (final d in details) {
        setMap[d.setIndex] = (setMap[d.setIndex] ?? 0) + 1;
      }
      if (setMap.isNotEmpty) {
        final maxSet = setMap.keys.reduce(max);
        reconstructedSplits = List.generate(maxSet + 1, (i) => setMap[i] ?? 0);
      }
      if (widget.workout.levelId != null && widget.workout.difficulty != null) {
        reconstructedTargets =
            TrainingData.programs[widget.workout.levelId]
                ?[widget.workout.difficulty] ??
            [];
      }
    }

    if (mounted) {
      setState(() {
        _repDetails          = details;
        _reconstructedSplits  = reconstructedSplits;
        _reconstructedTargets = reconstructedTargets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = (widget.workout.count * 0.5).round();
    final mins     = widget.workout.durationSeconds ~/ 60;
    final secs     = widget.workout.durationSeconds % 60;
    final locale   = context.watch<SettingsProvider>().locale;

    final levelStr = _levelStr(context);

    final splits     = widget.splits.isNotEmpty ? widget.splits : _reconstructedSplits;
    final targetReps = widget.targetReps.isNotEmpty ? widget.targetReps : _reconstructedTargets;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('training_completed')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: context.t('share_workout'),
            onPressed: () => _showShareSheet(context, splits),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(
            dateStr:      AppLocalizations.formatDate(widget.workout.date, locale),
            level:        levelStr,
            totalReps:    widget.workout.count,
            duration:     context.tp('min_sec', {
              'min': '$mins',
              'sec': secs.toString().padLeft(2, '0'),
            }),
            calories:     context.tp('kcal_approx', {'n': '$calories'}),
            verifiedReps: widget.verifiedReps,
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
          if (widget.history != null) ...[
            const SizedBox(height: 20),
            _WeeklyCard(history: widget.history!, baseDate: widget.workout.date),
          ],
          if (_repDetails.length >= 2) ...[
            const SizedBox(height: 20),
            _SensorSection(details: _repDetails),
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
          Text('$label:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
            Text(target!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(width: 10),
            Text('|', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  // ── Streak (1-day-gap tolerance) ──────────────────────────────────────────

  static int _streak(List<Workout> history, DateTime today) {
    if (history.isEmpty) return 0;

    // Unique training days, newest first.
    final days = history
        .map((w) => DateTime(w.date.year, w.date.month, w.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    // Streak is "active" only if the last session is ≤ 2 calendar days ago
    // (today or yesterday with 1 rest-day tolerance).
    if (today.difference(days.first).inDays > 2) return 0;

    int count = 1;
    for (int i = 1; i < days.length; i++) {
      // Gap between consecutive training days must be ≤ 2 (at most 1 rest day).
      if (days[i - 1].difference(days[i]).inDays <= 2) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  // ── Weekly volume (total reps) ────────────────────────────────────────────

  static int _weekVolume(List<Workout> history, DateTime monday) =>
      history.fold(0, (s, w) {
        final d    = DateTime(w.date.year, w.date.month, w.date.day);
        final diff = d.difference(monday).inDays;
        return (diff >= 0 && diff < 7) ? s + w.count : s;
      });

  // ── Weekly tempo: avg reps/min per session (durationSeconds > 0 only) ────

  static double _weekTempo(List<Workout> history, DateTime monday) {
    final sessions = history.where((w) {
      if (w.durationSeconds == 0) return false;
      final d    = DateTime(w.date.year, w.date.month, w.date.day);
      final diff = d.difference(monday).inDays;
      return diff >= 0 && diff < 7;
    }).toList();
    if (sessions.isEmpty) return 0.0;
    return sessions.fold(0.0, (s, w) => s + w.count / (w.durationSeconds / 60.0))
        / sessions.length;
  }

  // ── Delta label: "↑ 15 %" / "↓ 5 %" / "" ────────────────────────────────

  static ({String text, bool positive}) _delta(double current, double prev) {
    if (prev == 0 || current == 0) return (text: '', positive: true);
    final pct = ((current - prev) / prev * 100).round();
    if (pct == 0) return (text: '= 0 %', positive: true);
    return (
      text:     '${pct > 0 ? '↑' : '↓'} ${pct.abs()} %',
      positive: pct > 0,
    );
  }

  static String _compact(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final today      = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final monday     = today.subtract(Duration(days: today.weekday - 1));
    final prevMonday = monday.subtract(const Duration(days: 7));

    // Daily reps for circle display.
    final daily = <int, int>{};
    for (final w in history) {
      final d    = DateTime(w.date.year, w.date.month, w.date.day);
      final diff = d.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        daily[diff] = (daily[diff] ?? 0) + w.count;
      }
    }

    final todayOffset = today.difference(monday).inDays;
    final streak      = _streak(history, today);
    final currVol     = _weekVolume(history, monday);
    final prevVol     = _weekVolume(history, prevMonday);
    final currTempo   = _weekTempo(history, monday);
    final prevTempo   = _weekTempo(history, prevMonday);
    final volDelta    = _delta(currVol.toDouble(), prevVol.toDouble());
    final tempoDelta  = _delta(currTempo, prevTempo);

    final primary   = Theme.of(context).colorScheme.primary;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('week_overview'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (streak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 3),
                      Text(
                        context.tp('streak_days', {'n': '$streak'}),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:      primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Day circles ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final reps    = daily[i] ?? 0;
                final trained = reps > 0;
                final isToday = i == todayOffset;
                return Column(
                  children: [
                    Text(
                      context.t('weekday_$i'),
                      style: TextStyle(
                        fontSize:   11,
                        color:      isToday ? primary : hintColor,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: trained
                            ? primary.withValues(alpha: 0.85)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                                fontSize:   10,
                                fontWeight: FontWeight.bold,
                                color:      Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // ── Volume row ─────────────────────────────────────────────────
            _MetricRow(
              icon:      Icons.bar_chart,
              value:     context.tp('week_total', {'n': '$currVol'}),
              delta:     volDelta.text,
              deltaPos:  volDelta.positive,
              subLabel:  context.t('vs_prev_week'),
              hintColor: hintColor,
              primary:   primary,
            ),
            const SizedBox(height: 6),
            // ── Tempo row ──────────────────────────────────────────────────
            if (currTempo > 0)
              _MetricRow(
                icon:      Icons.speed,
                value:     '${currTempo.toStringAsFixed(1)} ${context.t('reps_per_min')}',
                delta:     tempoDelta.text,
                deltaPos:  tempoDelta.positive,
                subLabel:  context.t('vs_prev_week'),
                hintColor: hintColor,
                primary:   primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String   value;
  final String   delta;
  final bool     deltaPos;
  final String   subLabel;
  final Color    hintColor;
  final Color    primary;

  const _MetricRow({
    required this.icon,
    required this.value,
    required this.delta,
    required this.deltaPos,
    required this.subLabel,
    required this.hintColor,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = delta.isEmpty
        ? hintColor
        : deltaPos ? Colors.green : Colors.orange;

    return Row(
      children: [
        Icon(icon, size: 15, color: hintColor),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const Spacer(),
        if (delta.isNotEmpty) ...[
          Text(
            delta,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.bold,
              color:      deltaColor,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(subLabel, style: TextStyle(fontSize: 11, color: hintColor)),
      ],
    );
  }
}

// ── Sensor chart section ──────────────────────────────────────────────────────

class _SensorSection extends StatelessWidget {
  final List<RepDetail> details;

  const _SensorSection({required this.details});

  static ({double min, double max, double avg, double variance})
      _stats(List<double> deltas) {
    if (deltas.isEmpty) {
      return (min: 0.0, max: 0.0, avg: 0.0, variance: 0.0);
    }
    final mn  = deltas.reduce(min);
    final mx  = deltas.reduce(max);
    final avg = deltas.fold(0.0, (s, v) => s + v) / deltas.length;
    final vr  = deltas.fold(0.0, (s, v) => s + (v - avg) * (v - avg)) /
        deltas.length;
    return (min: mn, max: mx, avg: avg, variance: vr);
  }

  static List<double> _deltas(List<double> values) {
    final result = <double>[];
    for (var i = 1; i < values.length; i++) {
      result.add((values[i] - values[i - 1]).abs());
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final primary   = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final peakSpots = details
        .map((d) => FlSpot(d.timestampMs / 1000.0, d.peakG))
        .toList();
    final proxSpots = details
        .map((d) => FlSpot(d.timestampMs / 1000.0, d.proximityVal))
        .toList();

    final peakDeltas = _deltas(details.map((d) => d.peakG).toList());
    final proxDeltas = _deltas(details.map((d) => d.proximityVal).toList());
    final peakStats  = _stats(peakDeltas);
    final proxStats  = _stats(proxDeltas);

    String fmt(double v) => v.toStringAsFixed(2);

    // Local helper so header style can reference hintColor from context.
    TableRow statRow(
      String label, String mn, String mx, String avg, String vr, {
      bool isHeader = false,
    }) {
      final style = isHeader
          ? TextStyle(fontSize: 10, color: hintColor, fontWeight: FontWeight.bold)
          : const TextStyle(fontSize: 10);
      return TableRow(
        children: [label, mn, mx, avg, vr]
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(s, style: style),
                ))
            .toList(),
      );
    }

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            context.t('sensor_chart_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          initiallyExpanded: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniLineChart(spots: peakSpots, label: context.t('peak_g_label'),    color: primary),
                  const SizedBox(height: 12),
                  _MiniLineChart(spots: proxSpots, label: context.t('proximity_label'), color: secondary),
                  const SizedBox(height: 16),
                  Text(
                    context.t('stat_diff_label'),
                    style: TextStyle(fontSize: 11, color: hintColor),
                  ),
                  const SizedBox(height: 6),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(1.5),
                      4: FlexColumnWidth(1.5),
                    },
                    children: [
                      statRow('', context.t('stat_min'), context.t('stat_max'),
                          context.t('stat_avg'), context.t('stat_var'),
                          isHeader: true),
                      statRow(
                        context.t('peak_g_label'),
                        fmt(peakStats.min), fmt(peakStats.max),
                        fmt(peakStats.avg), fmt(peakStats.variance),
                      ),
                      statRow(
                        context.t('proximity_label'),
                        fmt(proxStats.min), fmt(proxStats.max),
                        fmt(proxStats.avg), fmt(proxStats.variance),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini line chart ───────────────────────────────────────────────────────────

class _MiniLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String       label;
  final Color        color;

  const _MiniLineChart({
    required this.spots,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) return const SizedBox.shrink();
    final rawMax = spots.map((s) => s.y).reduce(max);
    final maxY   = (rawMax * 1.2).clamp(0.1, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        SizedBox(
          height: 90,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots:        spots,
                  isCurved:     false,
                  color:        color,
                  barWidth:     1.5,
                  dotData:      const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show:  true,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
              ],
              minY: 0,
              maxY: maxY,
              titlesData: FlTitlesData(
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 32,
                    getTitlesWidget: (v, m) => Text(
                      v.toStringAsFixed(1),
                      style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles:   true,
                    reservedSize: 16,
                    getTitlesWidget: (v, m) => Text(
                      '${v.toInt()}s',
                      style: TextStyle(fontSize: 8, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
              gridData:   const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}

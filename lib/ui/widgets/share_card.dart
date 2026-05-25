import 'package:flutter/material.dart';

import '../../models/workout.dart';

/// Fixed-size workout summary card intended for screenshot sharing.
/// Design is always dark/branded, independent of the app's current theme.
class ShareCard extends StatelessWidget {
  final Workout      workout;
  final String       formattedDate;
  /// Sub-label shown below the rep count (splits text or free-training label).
  final String?      subLabel;
  /// Raw per-set rep counts — used to draw the mini bar chart.
  /// Pass an empty list for free training.
  final List<int>    splits;

  const ShareCard({
    super.key,
    required this.workout,
    required this.formattedDate,
    required this.splits,
    this.subLabel,
  });

  static const _purple   = Color(0xFF7C6DFF);
  static const _darkBg   = Color(0xFF0E0E1A);
  static const _darkCard = Color(0xFF1A1A2E);

  // Show bar chart only when there are 2–12 sets (above that it gets too cramped).
  bool get _showBars => splits.length >= 2 && splits.length <= 12;

  @override
  Widget build(BuildContext context) {
    final calories    = (workout.count * 0.5).round();
    final mins        = workout.durationSeconds ~/ 60;
    final secs        = workout.durationSeconds % 60;
    final durationStr = '${mins}m ${secs.toString().padLeft(2, '0')}s';

    final level      = workout.levelId;
    final difficulty = workout.difficulty;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkCard, _darkBg],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.35), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Purple accent line at top ─────────────────────────────────
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purple, Color(0xFF9B8FFF), Colors.transparent],
                  stops:  [0.0, 0.5, 1.0],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.fitness_center, color: _purple, size: 18),
                      const SizedBox(width: 7),
                      const Text(
                        'ApexPush',
                        style: TextStyle(
                          color:         _purple,
                          fontSize:      13,
                          fontWeight:    FontWeight.bold,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Rep count + level badge ───────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${workout.count}',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   68,
                          fontWeight: FontWeight.w900,
                          height:     1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Push-Ups',
                              style: TextStyle(
                                color:      Colors.white70,
                                fontSize:   17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (level != null && level.isNotEmpty &&
                                difficulty != null && difficulty.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _LevelBadge(level: level, difficulty: difficulty),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ── Sub-label (splits text or free-training) ─────────────
                  if (subLabel != null && !_showBars) ...[
                    const SizedBox(height: 4),
                    Text(
                      subLabel!,
                      style: const TextStyle(
                        color:         Colors.white38,
                        fontSize:      13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],

                  // ── Set bar chart ─────────────────────────────────────────
                  if (_showBars) ...[
                    const SizedBox(height: 16),
                    _SetBars(splits: splits),
                  ],

                  const SizedBox(height: 16),

                  // ── Stats chips ───────────────────────────────────────────
                  Wrap(
                    spacing:    8,
                    runSpacing: 8,
                    children: [
                      _Chip(icon: Icons.timer_outlined,        label: durationStr),
                      _Chip(icon: Icons.local_fire_department, label: '≈$calories kcal'),
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

// ── Level badge ───────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  final String difficulty;

  const _LevelBadge({required this.level, required this.difficulty});

  static Color _diffColor(String d) => switch (d) {
        'Easy'   => const Color(0xFF4CAF50),
        'Normal' => const Color(0xFFFF9800),
        'Hard'   => const Color(0xFFF44336),
        _        => const Color(0xFF9E9E9E),
      };

  @override
  Widget build(BuildContext context) {
    final color = _diffColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        '$level · $difficulty',
        style: TextStyle(
          color:      color,
          fontSize:   10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Set bar chart ─────────────────────────────────────────────────────────────

class _SetBars extends StatelessWidget {
  final List<int> splits;

  const _SetBars({required this.splits});

  static const _maxBarHeight = 42.0;
  static const _purple       = Color(0xFF7C6DFF);

  @override
  Widget build(BuildContext context) {
    final maxReps = splits.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: splits.asMap().entries.map((entry) {
        final i    = entry.key;
        final reps = entry.value;
        final frac = maxReps > 0 ? reps / maxReps : 0.0;
        final h    = (_maxBarHeight * frac).clamp(6.0, _maxBarHeight);
        // Bars fade slightly from first (brightest) to last.
        final opacity = 0.55 + 0.45 * (1 - i / splits.length);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rep count label above bar (only if bars are wide enough)
                if (splits.length <= 8)
                  Text(
                    '$reps',
                    style: TextStyle(
                      color:    Colors.white.withValues(alpha: 0.45),
                      fontSize: 9,
                    ),
                  ),
                const SizedBox(height: 2),
                Container(
                  height:     h,
                  decoration: BoxDecoration(
                    color:        _purple.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Stats chip ────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String   label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

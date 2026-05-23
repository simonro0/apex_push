import 'package:flutter/material.dart';

import '../../models/workout.dart';

/// Fixed-size workout summary card intended for screenshot sharing.
/// Design is always dark/branded, independent of the app's current theme.
class ShareCard extends StatelessWidget {
  final Workout workout;
  final String  formattedDate;
  final String  levelStr;

  const ShareCard({
    super.key,
    required this.workout,
    required this.formattedDate,
    required this.levelStr,
  });

  static const _purple    = Color(0xFF7C6DFF);
  static const _darkBg    = Color(0xFF0E0E1A);
  static const _darkCard  = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final calories    = (workout.count * 0.5).round();
    final mins        = workout.durationSeconds ~/ 60;
    final secs        = workout.durationSeconds % 60;
    final durationStr = '${mins}m ${secs.toString().padLeft(2, '0')}s';

    return Container(
      width:   360,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkCard, _darkBg],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.fitness_center, color: _purple, size: 18),
              const SizedBox(width: 7),
              const Text(
                'ApexPush',
                style: TextStyle(
                  color:       _purple,
                  fontSize:    13,
                  fontWeight:  FontWeight.bold,
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
          const SizedBox(height: 18),
          // ── Rep count ──────────────────────────────────────────────────────
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
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Push-Ups',
                  style: TextStyle(
                    color:      Colors.white70,
                    fontSize:   17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ── Level label ────────────────────────────────────────────────────
          Text(
            levelStr,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // ── Stats chips ────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(icon: Icons.timer_outlined,         label: durationStr),
              _Chip(icon: Icons.local_fire_department,  label: '≈$calories kcal'),
            ],
          ),
        ],
      ),
    );
  }
}

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

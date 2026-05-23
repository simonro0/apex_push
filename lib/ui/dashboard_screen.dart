import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/workout_provider.dart';
import '../models/workout.dart';
import 'level_picker_screen.dart';
import 'notification_screen.dart';
import 'record_screen.dart';
import 'settings_screen.dart';
import 'workout/workout_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      final p = context.read<WorkoutProvider>();
      p.loadHistoryFromDb();
      p.loadActiveProgram();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('app_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: context.t('notifications'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: context.t('settings'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsBar(provider: provider),
          _ActiveProgramTile(
            program: provider.activeProgram,
            onTap: () => _openLevelPicker(context, provider),
          ),
          const Expanded(child: _HeroImage()),
          _NavigationButtons(provider: provider),
        ],
      ),
    );
  }

  Future<void> _openLevelPicker(
      BuildContext context, WorkoutProvider provider) async {
    final result = await Navigator.push<ActiveProgram>(
      context,
      MaterialPageRoute(
        builder: (_) => LevelPickerScreen(current: provider.activeProgram),
      ),
    );
    if (result != null) {
      await provider.saveActiveProgram(result);
    }
  }
}

// ── Hero image ────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pushup.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.provider});
  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatCell(
            label: context.t('best_record'),
            value: '${provider.bestDayCount}/d',
          ),
          _StatCell(
            label: context.t('total'),
            value: '${provider.totalCount}',
          ),
          _StatCell(
            label: context.t('average'),
            value: '${provider.averageDailyCount.toStringAsFixed(0)}/d',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

// ── Active programme tile ─────────────────────────────────────────────────────

class _ActiveProgramTile extends StatelessWidget {
  const _ActiveProgramTile({required this.program, required this.onTap});
  final ActiveProgram program;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, size: 18),
            const SizedBox(width: 8),
            Text(
              '${context.t('current_level')}: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              program.toString(),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Navigation buttons (TRAINING / PRACTICE / RECORD) ─────────────────────────

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({required this.provider});
  final WorkoutProvider provider;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  context.t('training'),
                  style: const TextStyle(fontSize: 17),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.self_improvement, size: 20),
                    label: Text(
                      context.t('practice'),
                      style: const TextStyle(fontSize: 15),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const WorkoutScreen(isFreeTraining: true),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart, size: 20),
                    label: Text(
                      context.t('record'),
                      style: const TextStyle(fontSize: 15),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecordScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

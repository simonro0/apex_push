import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/csv_service.dart';
import '../logic/workout_provider.dart';
import '../models/workout.dart';
import 'level_picker_screen.dart';
import 'record_screen.dart';
import 'widgets/workout_stat_card.dart';
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
        title: const Text('ApexPush'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'CSV exportieren',
            onPressed: () => CsvService.exportToCsv(provider.history),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'CSV importieren',
            onPressed: () => _importCsv(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '.puud importieren',
            onPressed: () => _importPuud(context, provider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatsBar(provider: provider),
          _ActiveProgramTile(
            program: provider.activeProgram,
            onTap:   () => _openLevelPicker(context, provider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Verlauf', style: Theme.of(context).textTheme.headlineSmall),
                if (provider.history.isNotEmpty)
                  Text(
                    '${provider.history.length} Sessions',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            child: provider.history.isEmpty
                ? const Center(child: Text('Kein Training vorhanden. Jetzt starten!'))
                : ListView.builder(
                    itemCount: provider.history.length,
                    itemBuilder: (_, i) => WorkoutStatCard(provider.history[i]),
                  ),
          ),
          _NavigationButtons(provider: provider),
        ],
      ),
    );
  }

  // ── Level picker ───────────────────────────────────────────────────────────

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

  // ── Import helpers ─────────────────────────────────────────────────────────

  Future<void> _importCsv(BuildContext context, WorkoutProvider provider) async {
    final imported = await CsvService.importFromCsv();
    if (!context.mounted) return;
    if (imported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Daten importiert.')),
      );
      return;
    }
    await provider.saveMultipleWorkouts(imported);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${imported.length} Einträge importiert.')),
    );
  }

  Future<void> _importPuud(BuildContext context, WorkoutProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datei wird geöffnet…')),
    );
    final count = await provider.importFromPuud();
    if (!context.mounted) return;
    final msg = switch (count) {
      -1 => 'Abgebrochen.',
      0  => 'Keine Daten gefunden.',
      _  => '$count Einträge importiert.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          _StatCell(label: 'Best Record', value: '${provider.bestDayCount}/d'),
          _StatCell(label: 'Total',       value: '${provider.totalCount}'),
          _StatCell(
            label: 'Average',
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
  final VoidCallback  onTap;

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
              'Aktuelles Level: ',
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
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
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
                label: const Text('TRAINING', style: TextStyle(fontSize: 17)),
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
                    label: const Text('PRACTICE', style: TextStyle(fontSize: 15)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutScreen(isFreeTraining: true),
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
                    label: const Text('RECORD', style: TextStyle(fontSize: 15)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordScreen(history: provider.history),
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

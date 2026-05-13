import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/csv_service.dart';
import '../logic/workout_provider.dart';
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
          _ActiveProgramTile(program: provider.activeProgram.toString()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('History', style: Theme.of(context).textTheme.headlineSmall),
                if (provider.history.isNotEmpty)
                  Text(
                    '${provider.history.length} sessions',
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('START TRAINING'),
        icon: const Icon(Icons.play_arrow),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutScreen()),
        ),
      ),
    );
  }

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
  const _ActiveProgramTile({required this.program});
  final String program;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, size: 18),
          const SizedBox(width: 8),
          Text('Aktuelles Level: ', style: Theme.of(context).textTheme.bodyMedium),
          Text(program, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

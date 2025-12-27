import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/csv_service.dart';
import '../../logic/workout_provider.dart';
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
    // Use addPostFrameCallback to ensure the widget tree is built
    // before we trigger provider updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutProvider>();
      provider.loadHistoryFromDb();
      provider.loadPlan();
    });
  }

  @override
  Widget build(BuildContext context) {
    // We use context.watch here so the UI rebuilds whenever
    // the provider calls notifyListeners()
    final provider = context.watch<WorkoutProvider>();
    final plan = provider.plan;
    final history = provider.history;

    return Scaffold(
      appBar: AppBar(
        title: Text("ApexPush"),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: () => CsvService.exportToCsv(history),
            tooltip: "Export CSV",
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final imported = await CsvService.importFromCsv();
              if (imported.isNotEmpty) {
                await provider.saveMultipleWorkouts(imported);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Imported ${imported.length} workouts"),
                  ),
                );
              }
            },
            tooltip: "Import CSV",
          ),
        ],
      ),
      body: Column(
        children: [
          // Goal Overview
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text("Daily Goal", style: TextStyle(fontSize: 18)),
                Text(
                  "${plan.dailyTarget}",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                // Optional: You could calculate progress for the current day here
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "History",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (history.isNotEmpty)
                  Text(
                    "${history.length} sessions",
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),

          Expanded(
            child: history.isEmpty
                ? Center(child: Text("No workouts yet. Start training!"))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return WorkoutStatCard(history[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        label: Text("START TRAINING"),
        icon: Icon(Icons.play_arrow),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutScreen()),
          );
        },
      ),
    );
  }
}

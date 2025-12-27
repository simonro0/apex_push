import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/csv_service.dart';
import '../../logic/workout_provider.dart';
import 'widgets/workout_stat_card.dart';
import 'workout/workout_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final plan = provider.plan;

    return Scaffold(
      appBar: AppBar(
        title: Text("ApexPush"),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: () => CsvService.exportToCsv(provider.history),
            tooltip: "Export CSV",
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () async {
              final imported = await CsvService.importFromCsv();
              provider.saveMultipleWorkouts(imported);
            },
            tooltip: "Import CSV",
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. STATS OVERVIEW CARD
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
                LinearProgressIndicator(
                  value: 0.4, // Calculate: totalToday / dailyTarget
                  backgroundColor: Colors.black26,
                ),
              ],
            ),
          ),

          // 2. RECENT ACTIVITY HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "History",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextButton(onPressed: () {}, child: Text("See All")),
              ],
            ),
          ),

          // 3. HISTORY LIST (Marked Data)
          Expanded(
            child: ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                return WorkoutStatCard(provider.history[index]);
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

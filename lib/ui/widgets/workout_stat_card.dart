// ui/widgets/workout_stat_card.dart
import 'package:flutter/material.dart';

import '../../models/workout.dart';

class WorkoutStatCard extends StatelessWidget {
  final Workout workout;

  const WorkoutStatCard(this.workout, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        workout.isImported ? Icons.cloud_download : Icons.fitness_center,
        color: workout.isImported ? Colors.blue : Colors.green,
      ),
      title: Text("${workout.count} PushUps"),
      subtitle: Text(
        "${workout.date.day}/${workout.date.month} - ${workout.avgRpm.toStringAsFixed(1)} RPM",
      ),
      trailing: workout.isVerified
          ? Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.warning, color: Colors.amber), // Fact-check visual
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
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
      title: Text('${workout.count} ${context.t('pushups')}'),
      subtitle: Text(
        '${workout.date.day}/${workout.date.month}'
        ' – ${workout.avgRpm.toStringAsFixed(1)} ${context.t('rpm')}',
      ),
      trailing: workout.isVerified
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.warning, color: Colors.amber),
    );
  }
}

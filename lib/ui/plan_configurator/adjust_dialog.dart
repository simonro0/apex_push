import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_provider.dart';

void showAdjustmentDialog(BuildContext context, int oldReps, int newReps) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Adjust Training Plan?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Based on your feedback, we suggest an increase:"),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("$oldReps", style: TextStyle(color: Colors.grey)),
              Icon(Icons.arrow_forward),
              Text(
                "$newReps",
                style: TextStyle(color: Colors.green, fontSize: 24),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("DECLINE"),
        ),
        ElevatedButton(
          onPressed: () => context.read<WorkoutProvider>().saveNewPlan(newReps),
          child: Text("ACCEPT"),
        ),
      ],
    ),
  );
}

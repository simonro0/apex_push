import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_provider.dart';

class WorkoutScreen extends StatefulWidget {
  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Start sensors and reset counter when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().startWorkout();
    });
  }

  // Helper to show the feedback dialog after finishing
  void _finishWorkout(WorkoutProvider provider) async {
    // 1. Save the workout data
    await provider.saveWorkout();

    // 2. Ask for feedback to trigger adaptive logic
    String? feedback = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Workout Complete!"),
        content: Text("How did the intensity feel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, "Too Hard"),
            child: Text("TOUGH"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, "Just Right"),
            child: Text("PERFECT"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, "Too Easy"),
            child: Text("EASY"),
          ),
        ],
      ),
    );

    if (feedback != null) {
      // 3. Calculate new target
      int oldTarget = provider.plan.dailyTarget;
      provider.adjustDifficulty(feedback);
      int newTarget = provider.plan.dailyTarget;

      // 4. If target changed, show the "Accept/Decline" Preview
      if (oldTarget != newTarget) {
        _showAdjustmentPreview(context, oldTarget, newTarget);
      } else {
        Navigator.pop(context); // Go back to Dashboard
      }
    }
  }

  void _showAdjustmentPreview(
    BuildContext context,
    int oldTarget,
    int newTarget,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Plan Evolution"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Based on your feedback, we suggest adjusting your goal:"),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$oldTarget",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Icon(Icons.arrow_right_alt, size: 40),
                Text(
                  "$newTarget",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Decline: Revert the plan in provider
              context.read<WorkoutProvider>().updatePlanManual(oldTarget);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("KEEP OLD"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Call the missing function to persist the plan
              await context.read<WorkoutProvider>().saveNewPlan(newTarget);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("ACCEPT NEW"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      backgroundColor: Colors.black, // High contrast for workout
      body: GestureDetector(
        onTap: () => provider.incrementCount(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // The "Pad" feedback
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "TAP WITH NOSE / CHEST",
                    style: TextStyle(color: Colors.white54),
                  ),
                  Text(
                    "${provider.currentCount}",
                    style: TextStyle(
                      fontSize: 180,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Finish Button
            Positioned(
              bottom: 50,
              left: 50,
              right: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.all(20),
                ),
                onPressed: () => _finishWorkout(provider),
                child: Text(
                  "FINISH SESSION",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

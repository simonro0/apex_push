import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_provider.dart';
import '../../models/training_data.dart';

class WorkoutScreen extends StatefulWidget {
  /// When true the session is a free practice round (not bound to a level).
  final bool isFreeTraining;

  const WorkoutScreen({super.key, this.isFreeTraining = false});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutProvider>().startWorkout();
    });
  }

  Future<void> _finish(WorkoutProvider provider) async {
    await provider.saveWorkout(isFreeTraining: widget.isFreeTraining);

    if (!mounted) return;

    final direction = await _showFeedbackDialog(context);
    if (direction == null || !mounted) return;

    await provider.stepDifficulty(direction);
    if (!mounted) return;

    if (direction != 'keep') {
      await _showLevelChangedDialog(context, provider);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: provider.incrementCount,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isFreeTraining ? 'FREIES TRAINING' : 'TAP WITH NOSE / CHEST',
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                  Text(
                    '${provider.currentCount}',
                    style: const TextStyle(
                      fontSize: 180,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 50,
              left: 50,
              right: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(20),
                ),
                onPressed: () => _finish(provider),
                child: const Text(
                  'FINISH SESSION',
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

Future<String?> _showFeedbackDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Training beendet'),
        content: const Text('Wie war die Schwierigkeit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'down'),
            child: const Text('ZU SCHWER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('PASST SO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'up'),
            child: const Text('ZU LEICHT'),
          ),
        ],
      ),
    );

Future<void> _showLevelChangedDialog(
    BuildContext context, WorkoutProvider provider) async {
  final p = provider.activeProgram;
  final reps = TrainingData.getReps(p.unitId, p.difficulty);
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Level angepasst'),
      content: Text(
        'Neues Level: ${p.unitId} (${p.difficulty})\n'
        'Sätze: ${reps.join(' – ')}',
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

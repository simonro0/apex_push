import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_provider.dart';
import '../../models/training_data.dart';

class WorkoutScreen extends StatefulWidget {
  final bool isFreeTraining;

  const WorkoutScreen({super.key, this.isFreeTraining = false});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Structured-mode set tracking
  List<int> _targetReps = [];
  int _currentSet = 0;   // 0-based
  int _setStartCount = 0; // provider.currentCount at the beginning of this set

  // Rest timer
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  bool _inRest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<WorkoutProvider>();
      p.startWorkout();
      if (!widget.isFreeTraining) {
        final prog = p.activeProgram;
        setState(() {
          _targetReps = TrainingData.getReps(prog.unitId, prog.difficulty);
        });
      }
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  int _setCountFrom(WorkoutProvider p) => p.currentCount - _setStartCount;

  int get _setsTotal => _targetReps.length;

  int _targetFor(int setIndex) =>
      setIndex < _targetReps.length ? _targetReps[setIndex] : 0;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onTap(WorkoutProvider provider) {
    provider.incrementCount();
    HapticFeedback.lightImpact();
  }

  void _finishSet(WorkoutProvider provider) {
    if (_currentSet >= _setsTotal - 1) {
      _finish(provider);
      return;
    }
    _restTimer?.cancel();
    setState(() {
      _setStartCount = provider.currentCount;
      _currentSet++;
      _inRest = true;
      _restSecondsLeft = TrainingData.getRestSeconds(provider.activeProgram.difficulty);
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_restSecondsLeft <= 1) {
          t.cancel();
          _inRest = false;
        } else {
          _restSecondsLeft--;
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _inRest = false);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.isFreeTraining
          ? _buildFreeTraining(provider)
          : _buildStructured(provider),
    );
  }

  // ── Free-training mode ────────────────────────────────────────────────────

  Widget _buildFreeTraining(WorkoutProvider provider) {
    return GestureDetector(
      onTap: () => _onTap(provider),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'FREIES TRAINING',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
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
    );
  }

  // ── Structured mode ───────────────────────────────────────────────────────

  Widget _buildStructured(WorkoutProvider provider) {
    if (_inRest) return _buildRestPhase(provider);
    return _buildActiveSet(provider);
  }

  Widget _buildActiveSet(WorkoutProvider provider) {
    final setCount = _setCountFrom(provider);
    final target   = _targetFor(_currentSet);
    final isLast   = _currentSet >= _setsTotal - 1;
    final atTarget = setCount >= target;

    return GestureDetector(
      onTap: () => _onTap(provider),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Satz ${_currentSet + 1} von $_setsTotal',
                  style: const TextStyle(color: Colors.white54, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ziel: $target Wdh.',
                  style: const TextStyle(color: Colors.white38, fontSize: 15),
                ),
                Text(
                  '$setCount',
                  style: TextStyle(
                    fontSize: 160,
                    color: atTarget ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? Colors.redAccent : Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _finishSet(provider),
                  child: Text(
                    isLast ? 'TRAINING ABSCHLIESSEN' : 'SATZ ABSCHLIESSEN',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _finish(provider),
                  child: const Text(
                    'Training abbrechen',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestPhase(WorkoutProvider provider) {
    final nextTarget = _targetFor(_currentSet);
    final isLast3    = _restSecondsLeft <= 3;

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAUSE',
                style: TextStyle(color: Colors.white54, fontSize: 22, letterSpacing: 4),
              ),
              const SizedBox(height: 16),
              Text(
                '$_restSecondsLeft',
                style: TextStyle(
                  fontSize: 120,
                  color: isLast3 ? Colors.orangeAccent : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nächster Satz: $nextTarget Wdh.',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
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
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _skipRest,
            child: const Text('PAUSE ÜBERSPRINGEN', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

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
  final p    = provider.activeProgram;
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

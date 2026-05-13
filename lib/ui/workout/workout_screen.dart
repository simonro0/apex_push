import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../logic/workout_provider.dart';
import '../../models/training_data.dart';
import '../session_detail_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final bool isFreeTraining;

  const WorkoutScreen({super.key, this.isFreeTraining = false});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<int> _targetReps   = [];
  int  _currentSet        = 0;
  int  _setStartCount     = 0;

  Timer? _restTimer;
  int    _restSecondsLeft = 0;
  bool   _inRest          = false;

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

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _setCountFrom(WorkoutProvider p) => p.currentCount - _setStartCount;
  int get _setsTotal => _targetReps.length;
  int _targetFor(int i) => i < _targetReps.length ? _targetReps[i] : 0;

  /// Interpolates from light-green → deep-green as excess reps grow.
  Color _finishButtonColor(int setCount, int target) {
    if (setCount < target) return Colors.red.shade700;
    if (target == 0)       return Colors.green.shade600;
    final ratio = ((setCount - target) / max(target, 1) * 4).clamp(0.0, 1.0);
    return Color.lerp(Colors.green.shade300, Colors.green.shade900, ratio)!;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onTap(WorkoutProvider provider) {
    provider.incrementCount();
    HapticFeedback.lightImpact();
  }

  void _finishSet(WorkoutProvider provider) {
    provider.recordSetSplit(_setCountFrom(provider));

    if (_currentSet >= _setsTotal - 1) {
      _finish(provider);
      return;
    }

    _restTimer?.cancel();
    setState(() {
      _setStartCount   = provider.currentCount;
      _currentSet++;
      _inRest          = true;
      _restSecondsLeft =
          TrainingData.getRestSeconds(provider.activeProgram.difficulty);
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

  Future<void> _abort(WorkoutProvider provider) async {
    provider.recordSetSplit(_setCountFrom(provider));
    await _finish(provider);
  }

  Future<void> _finish(WorkoutProvider provider) async {
    _restTimer?.cancel();

    final isFree         = widget.isFreeTraining;
    final targetRepsCopy = List<int>.from(_targetReps);
    final splitsCopy     = List<int>.from(provider.sessionSplits);

    final workout = await provider.saveWorkout(isFreeTraining: isFree);
    if (!mounted) return;

    if (!isFree && splitsCopy.isNotEmpty) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(
            workout:    workout,
            splits:     splitsCopy,
            targetReps: targetRepsCopy,
          ),
        ),
      );
      if (!mounted) return;
    }

    if (!isFree) {
      final direction = await _showFeedbackDialog(context);
      if (direction == null || !mounted) return;

      await provider.stepDifficulty(direction);
      if (!mounted) return;

      if (direction != 'keep') {
        await _showLevelChangedDialog(context, provider);
      }
      if (!mounted) return;
    }

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

    final buttonColor = _finishButtonColor(setCount, target);
    final buttonLabel = atTarget
        ? (isLast ? 'TRAINING ABSCHLIESSEN' : 'SATZ ABSCHLIESSEN')
        : (isLast ? 'TRAINING ABBRECHEN'    : 'SATZ ABBRECHEN');

    return GestureDetector(
      onTap: () => _onTap(provider),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // ── Set overview (top) ────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: _SetOverview(
              setsTotal:    _setsTotal,
              currentSet:   _currentSet,
              targetReps:   _targetReps,
              splits:       provider.sessionSplits,
            ),
          ),

          // ── Counter ───────────────────────────────────────────────────────
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

          // ── Buttons (bottom) ──────────────────────────────────────────────
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!atTarget) {
                      final ok = await _showAbortSetDialog(context, isLast);
                      if (ok != true || !mounted) return;
                    }
                    _finishSet(provider);
                  },
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final ok = await _showAbortSessionDialog(context);
                    if (ok != true || !mounted) return;
                    _abort(provider);
                  },
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
        // ── Set overview (top) ──────────────────────────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: _SetOverview(
            setsTotal:  _setsTotal,
            currentSet: _currentSet,
            targetReps: _targetReps,
            splits:     provider.sessionSplits,
          ),
        ),

        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'PAUSE',
                style: TextStyle(
                    color: Colors.white54, fontSize: 22, letterSpacing: 4),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _skipRest,
            child: const Text('PAUSE ÜBERSPRINGEN',
                style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

// ── Set overview widget ───────────────────────────────────────────────────────

class _SetOverview extends StatelessWidget {
  const _SetOverview({
    required this.setsTotal,
    required this.currentSet,
    required this.targetReps,
    required this.splits,
  });

  final int        setsTotal;
  final int        currentSet;
  final List<int>  targetReps;
  final List<int>  splits;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(setsTotal, (i) {
          final target    = i < targetReps.length ? targetReps[i] : 0;
          final isDone    = i < currentSet;
          final isCurrent = i == currentSet;
          final achieved  = isDone && i < splits.length ? splits[i] : null;

          return _SetChip(
            index:    i,
            target:   target,
            achieved: achieved,
            isCurrent: isCurrent,
          );
        }),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({
    required this.index,
    required this.target,
    required this.achieved,
    required this.isCurrent,
  });

  final int  index;
  final int  target;
  final int? achieved;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final isDone = achieved != null;
    final ok     = isDone && achieved! >= target;

    Color bg;
    Color fg;
    if (isCurrent) {
      bg = Colors.white24;
      fg = Colors.white;
    } else if (isDone) {
      bg = ok ? Colors.green.shade800 : Colors.orange.shade800;
      fg = Colors.white;
    } else {
      bg = Colors.white10;
      fg = Colors.white38;
    }

    final label = isDone ? '${achieved!}' : '$target';
    final sublabel = isDone ? '/ $target' : 'Wdh.';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: Colors.white54, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'S${index + 1}',
            style: TextStyle(
              color: fg.withAlpha(180),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(color: fg.withAlpha(140), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

Future<bool?> _showAbortSetDialog(BuildContext context, bool isLast) =>
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isLast ? 'Training abbrechen?' : 'Satz abbrechen?'),
        content: Text(
          isLast
              ? 'Das Training wird mit den bisher erreichten Wiederholungen gespeichert.'
              : 'Der aktuelle Satz wird mit den bisher erreichten Wiederholungen gewertet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ZURÜCK'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              isLast ? 'TRAINING ABBRECHEN' : 'SATZ ABBRECHEN',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

Future<bool?> _showAbortSessionDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Training abbrechen?'),
        content: const Text(
          'Das Training wird mit den bisher erreichten Wiederholungen gespeichert.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('WEITERMACHEN'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ABBRECHEN',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

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

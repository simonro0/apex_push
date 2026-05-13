import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/audio_service.dart';
import '../../logic/settings_provider.dart';
import '../../logic/workout_provider.dart';
import '../../models/training_data.dart';
import '../../models/workout.dart';
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

  bool _targetReachedPlayed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p        = context.read<WorkoutProvider>();
      final settings = context.read<SettingsProvider>();

      await AudioService.instance.init();
      p.startWorkout(sensorThreshold: settings.sensorThreshold);

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

    final settings = context.read<SettingsProvider>();
    if (settings.audioEnabled) {
      if (settings.repSoundEnabled) {
        AudioService.instance.playRepTick();
      }
      if (!widget.isFreeTraining && !_targetReachedPlayed) {
        final setCount = _setCountFrom(provider);
        final target   = _targetFor(_currentSet);
        if (target > 0 && setCount >= target) {
          _targetReachedPlayed = true;
          AudioService.instance.playTargetReached();
        }
      }
    }
  }

  void _finishSet(WorkoutProvider provider) {
    provider.recordSetSplit(_setCountFrom(provider));

    if (_currentSet >= _setsTotal - 1) {
      _finish(provider);
      return;
    }

    _startRest(provider);
  }

  void _startRest(WorkoutProvider provider) {
    final settings = context.read<SettingsProvider>();
    final restSecs = settings.getRestSeconds(provider.activeProgram.difficulty);

    _restTimer?.cancel();
    setState(() {
      _setStartCount        = provider.currentCount;
      _currentSet++;
      _inRest               = true;
      _restSecondsLeft      = restSecs;
      _targetReachedPlayed  = false;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_restSecondsLeft <= 1) {
        t.cancel();
        setState(() => _inRest = false);
        if (settings.audioEnabled) AudioService.instance.playRestEnd();
      } else {
        setState(() => _restSecondsLeft--);
        if (settings.audioEnabled && _restSecondsLeft <= 3) {
          AudioService.instance.playCountdown();
        }
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() {
      _inRest              = false;
      _targetReachedPlayed = false;
    });
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

    // ── Show session detail ──────────────────────────────────────────────────
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

    // ── Post-training flow ───────────────────────────────────────────────────
    if (isFree) {
      final difficulty = provider.activeProgram.difficulty;
      final recommended = TrainingData.recommendUnit(workout.count, difficulty);
      final accepted = await _showPracticeRecommendationDialog(
          context, workout.count, recommended, difficulty);
      if (accepted == true && mounted) {
        await provider.saveActiveProgram(
            ActiveProgram(unitId: recommended, difficulty: difficulty));
      }
    } else {
      final direction = await _showFeedbackDialog(context);
      if (direction == null || !mounted) return;

      await provider.stepDifficulty(direction);
      if (!mounted) return;

      if (direction != 'keep') {
        await _showLevelChangedDialog(context, provider);
      }
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
                Text(
                  context.t('free_training'),
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
              child: Text(
                context.t('finish_session'),
                style: const TextStyle(fontSize: 20, color: Colors.white),
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
        ? context.tr(isLast ? 'finish_training' : 'finish_set')
        : context.tr(isLast ? 'abort_training_btn' : 'abort_set_btn');

    return GestureDetector(
      onTap: () => _onTap(provider),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
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
                Text(
                  context.tp('set_x_of_y', {
                    'set':   '${_currentSet + 1}',
                    'total': '$_setsTotal',
                  }),
                  style: const TextStyle(color: Colors.white54, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tp('target_reps', {'n': '$target'}),
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
                  child: Text(
                    context.t('abort_training_link'),
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
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
              Text(
                context.t('rest'),
                style: const TextStyle(
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
                context.tp('next_set_reps', {'n': '$nextTarget'}),
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
            child: Text(
              context.t('skip_rest'),
              style: const TextStyle(fontSize: 16),
            ),
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
            index:     i,
            target:    target,
            achieved:  achieved,
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

    final label    = isDone ? '${achieved!}' : '$target';
    final sublabel = isDone
        ? '/ $target'
        : context.t('reps_short');

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
        title: Text(context.tr(isLast ? 'abort_last_title' : 'abort_set_title')),
        content: Text(context.tr(isLast ? 'abort_last_msg' : 'abort_set_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('back')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr(isLast ? 'abort_training_btn' : 'abort_set_btn'),
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
        title: Text(context.tr('abort_session_title')),
        content: Text(context.tr('abort_session_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('keep_going')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.tr('abort'),
              style: const TextStyle(color: Colors.white),
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
        title: Text(context.tr('training_finished')),
        content: Text(context.tr('how_was_difficulty')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'down'),
            child: Text(context.tr('too_hard')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: Text(context.tr('just_right')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'up'),
            child: Text(context.tr('too_easy')),
          ),
        ],
      ),
    );

Future<bool?> _showPracticeRecommendationDialog(
    BuildContext context, int reps, String unitId, String difficulty) {
  final repsForLevel = TrainingData.getReps(unitId, difficulty);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: Text(context.tr('practice_rec_title')),
      content: Text(
        context.tp('practice_rec_body', {
          'n':    '$reps',
          'level': unitId,
          'diff':  difficulty,
          'reps':  repsForLevel.join(' – '),
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('skip')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr('apply')),
        ),
      ],
    ),
  );
}

Future<void> _showLevelChangedDialog(
    BuildContext context, WorkoutProvider provider) async {
  final p    = provider.activeProgram;
  final reps = TrainingData.getReps(p.unitId, p.difficulty);
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(context.tr('level_adjusted')),
      content: Text(
        context.tp('new_level_info', {
          'unit': p.unitId,
          'diff': p.difficulty,
          'reps': reps.join(' – '),
        }),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('ok')),
        ),
      ],
    ),
  );
}

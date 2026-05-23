import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/audio_service.dart';
import '../../logic/notification_service.dart';
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
  bool _isFinishing         = false;

  @override
  void initState() {
    super.initState();

    // Read target reps synchronously so the first frame shows correct values.
    if (!widget.isFreeTraining) {
      final prog = context.read<WorkoutProvider>().activeProgram;
      _targetReps = TrainingData.getReps(prog.unitId, prog.difficulty);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      context.read<WorkoutProvider>().startWorkout(
            sensorThreshold: settings.sensorThreshold,
          );
      WakelockPlus.enable();
    });
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _setCountFrom(WorkoutProvider p) => p.currentCount - _setStartCount;
  int get _setsTotal  => _targetReps.length;
  bool get _isBurnout => !widget.isFreeTraining && _currentSet >= _setsTotal;
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
        // Every 10th rep gets a more intense milestone tone.
        final count = provider.currentCount;
        if (count > 0 && count % 10 == 0) {
          AudioService.instance.playMilestone();
        } else {
          AudioService.instance.playRepTick();
        }
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

    if (_isBurnout) {
      _finish(provider);
      return;
    }

    // Skip rest before the burnout set so it starts immediately.
    if (_currentSet + 1 >= _setsTotal) {
      setState(() {
        _setStartCount       = provider.currentCount;
        _currentSet++;
        _targetReachedPlayed = false;
      });
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

    // Read settings before the async gap (context must not be used after await).
    final settings     = context.read<SettingsProvider>();
    final verifiedReps = provider.lastVerifiedReps;
    final workout      = await provider.saveWorkout(isFreeTraining: isFree);
    if (!mounted) return;

    // Reschedule streak reminder: fires once on workout.date + 2 days.
    if (settings.streakReminderEnabled) {
      final hoursLeft = 24 - settings.reminderHour;
      final locale    = settings.locale;
      await NotificationService.instance.scheduleStreakReminder(
        lastWorkoutDate: workout.date,
        hour:   settings.reminderHour,
        minute: settings.reminderMinute,
        title:  AppLocalizations.translate('streak_notif_title', locale),
        body:   AppLocalizations.translate('streak_notif_body', locale)
            .replaceAll('{h}', '$hoursLeft'),
      );
    }
    if (!mounted) return;

    // Capture history after save (includes the session just recorded).
    final historyCopy = List<Workout>.from(provider.history);

    // ── Show session detail ──────────────────────────────────────────────────
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          workout:      workout,
          splits:       splitsCopy,
          targetReps:   targetRepsCopy,
          verifiedReps: verifiedReps,
          history:      historyCopy,
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

    setState(() => _isFinishing = true);
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  Future<void> _handleBackPress(WorkoutProvider provider) async {
    final ok = await _showAbortSessionDialog(context);
    if (ok != true || !mounted) return;
    if (_inRest) {
      // Rest phase: set split was already recorded when rest started; just finish.
      _restTimer?.cancel();
      setState(() => _inRest = false);
      await _finish(provider);
    } else {
      await _abort(provider);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    return PopScope(
      canPop: _isFinishing,
      onPopInvokedWithResult: (didPop, r) {
        if (!didPop) _handleBackPress(provider);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: widget.isFreeTraining
            ? _buildFreeTraining(provider)
            : _buildStructured(provider),
      ),
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
    final setCount  = _setCountFrom(provider);
    final target    = _targetFor(_currentSet);
    final isBurnout = _isBurnout;
    final atTarget  = isBurnout || setCount >= target;

    final buttonColor = _finishButtonColor(setCount, target);
    final buttonLabel = atTarget
        ? context.tr(isBurnout ? 'finish_training' : 'finish_set')
        : context.tr('abort_set_btn');

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
              setsTotal:   _setsTotal,
              currentSet:  _currentSet,
              targetReps:  _targetReps,
              splits:      provider.sessionSplits,
              hasBurnout:  !widget.isFreeTraining,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isBurnout
                      ? context.t('burnout')
                      : context.tp('set_x_of_y', {
                          'set':   '${_currentSet + 1}',
                          'total': '$_setsTotal',
                        }),
                  style: const TextStyle(color: Colors.white54, fontSize: 20),
                ),
                const SizedBox(height: 6),
                if (!isBurnout)
                  Text(
                    context.tp('target_reps', {'n': '$target'}),
                    style: const TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                Text(
                  '$setCount',
                  style: TextStyle(
                    fontSize: 160,
                    color: (isBurnout && setCount > 0) || (!isBurnout && atTarget)
                        ? Colors.greenAccent
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isBurnout && target > 0 && setCount < target)
                  Text(
                    context.tp('countdown_remaining', {'n': '${target - setCount}'}),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                else if (!isBurnout && target > 0 && setCount > target)
                  Text(
                    context.tp('countdown_extra', {'n': '${setCount - target}'}),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
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
                      final ok = await _showAbortSetDialog(context, isBurnout);
                      if (ok != true || !mounted) return;
                    }
                    _finishSet(provider);
                  },
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final ok = await _showAbortSessionDialog(context);
                    if (ok != true || !mounted) return;
                    _abort(provider);
                  },
                  child: Text(
                    context.t('abort_training_link'),
                    style: const TextStyle(fontSize: 16),
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
    final nextTarget    = _targetFor(_currentSet);
    final nextIsBurnout = !widget.isFreeTraining && _currentSet >= _setsTotal;
    final isLast3       = _restSecondsLeft <= 3;

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
            hasBurnout: !widget.isFreeTraining,
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
                nextIsBurnout
                    ? context.t('burnout_next')
                    : context.tp('next_set_reps', {'n': '$nextTarget'}),
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
    this.hasBurnout = false,
  });

  final int        setsTotal;
  final int        currentSet;
  final List<int>  targetReps;
  final List<int>  splits;
  final bool       hasBurnout;

  @override
  Widget build(BuildContext context) {
    final burnoutIsCurrent = hasBurnout && currentSet >= setsTotal;
    final burnoutAchieved  =
        burnoutIsCurrent && setsTotal < splits.length ? splits[setsTotal] : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ...List.generate(setsTotal, (i) {
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
          if (hasBurnout)
            _BurnoutChip(
              isCurrent: burnoutIsCurrent,
              achieved:  burnoutAchieved,
            ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(color: fg.withAlpha(140), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Burnout chip ──────────────────────────────────────────────────────────────

class _BurnoutChip extends StatelessWidget {
  const _BurnoutChip({required this.isCurrent, this.achieved});
  final bool isCurrent;
  final int? achieved;

  @override
  Widget build(BuildContext context) {
    final Color bg = isCurrent ? Colors.deepOrange.shade800 : Colors.white10;
    final Color fg = isCurrent ? Colors.white : Colors.white38;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: Colors.orangeAccent, width: 1.5)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 14, color: fg.withAlpha(180)),
          Text(
            achieved != null ? '${achieved!}' : context.t('burnout_chip'),
            style: TextStyle(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            context.t('reps_short'),
            style: TextStyle(color: fg.withAlpha(140), fontSize: 11),
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

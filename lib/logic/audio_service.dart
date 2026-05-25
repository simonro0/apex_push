import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton audio service.
///
/// WAV bytes are synthesised once in [init] and each [AudioPlayer] source is
/// pre-loaded with [AudioPlayer.setSource] so that subsequent play calls only
/// need [AudioPlayer.seek] + [AudioPlayer.resume] — avoiding the
/// setSource/prepare round-trip (~50–200 ms on Android) that causes sounds to
/// be skipped during rapid rep sequences.  [ReleaseMode.stop] keeps the source
/// loaded after playback completes so the seek+resume pattern always works.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool   _initialized = false;
  double _volume      = 1.0;

  double get volume => _volume;
  set volume(double v) {
    _volume = v;
    if (!_initialized) return;
    for (final p in _repPool) {
      p.setVolume(v);
    }
    _countdownPlayer.setVolume(v);
    _restEndPlayer.setVolume(v);
    _targetPlayer.setVolume(v);
    _milestonePlayer.setVolume(v);
  }

  // Five players in round-robin so rapid rep ticks can overlap.
  final List<AudioPlayer> _repPool = [];
  int _repIdx = 0;

  // One player per distinct event sound.
  late final AudioPlayer _countdownPlayer;
  late final AudioPlayer _restEndPlayer;
  late final AudioPlayer _targetPlayer;
  late final AudioPlayer _milestonePlayer;

  // Pre-synthesised bytes. Sources are loaded once in init(); play calls only
  // seek to zero and resume — no per-call setSource overhead.
  late final Uint8List _repBytes;
  late final Uint8List _countdownBytes;
  late final Uint8List _restEndBytes;
  late final Uint8List _targetBytes;
  late final Uint8List _milestoneBytes;

  // ── Init / dispose ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    _repBytes       = _wav(hz: 880,  ms: 60,  vol: 0.45);
    _countdownBytes = _wav(hz: 660,  ms: 110, vol: 0.75);
    _restEndBytes   = _wav(hz: 1100, ms: 300, vol: 0.85);
    _targetBytes    = _wav(hz: 1320, ms: 200, vol: 0.80);
    _milestoneBytes = _wav(hz: 1100, ms: 150, vol: 0.90);

    // On Android, request a transient audio focus that ducks other audio
    // rather than taking full focus.  This eliminates the audio-focus
    // handshake delay that causes audible lag on Pixel devices.
    final audioCtx = defaultTargetPlatform == TargetPlatform.android
        ? AudioContext(
            android: AudioContextAndroid(
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              stayAwake: false,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.assistanceSonification,
            ),
          )
        : AudioContext();

    // Pre-load rep pool (5 slots for rapid tap sequences).
    for (var i = 0; i < 5; i++) {
      final p = AudioPlayer();
      await p.setAudioContext(audioCtx);
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setVolume(_volume);
      await p.setSource(BytesSource(_repBytes));
      _repPool.add(p);
    }

    // Pre-load event players.
    _countdownPlayer = AudioPlayer();
    await _countdownPlayer.setAudioContext(audioCtx);
    await _countdownPlayer.setReleaseMode(ReleaseMode.stop);
    await _countdownPlayer.setVolume(_volume);
    await _countdownPlayer.setSource(BytesSource(_countdownBytes));

    _restEndPlayer = AudioPlayer();
    await _restEndPlayer.setAudioContext(audioCtx);
    await _restEndPlayer.setReleaseMode(ReleaseMode.stop);
    await _restEndPlayer.setVolume(_volume);
    await _restEndPlayer.setSource(BytesSource(_restEndBytes));

    _targetPlayer = AudioPlayer();
    await _targetPlayer.setAudioContext(audioCtx);
    await _targetPlayer.setReleaseMode(ReleaseMode.stop);
    await _targetPlayer.setVolume(_volume);
    await _targetPlayer.setSource(BytesSource(_targetBytes));

    _milestonePlayer = AudioPlayer();
    await _milestonePlayer.setAudioContext(audioCtx);
    await _milestonePlayer.setReleaseMode(ReleaseMode.stop);
    await _milestonePlayer.setVolume(_volume);
    await _milestonePlayer.setSource(BytesSource(_milestoneBytes));

    _initialized = true;
  }

  void dispose() {
    for (final p in _repPool) {
      p.dispose();
    }
    if (_initialized) {
      _countdownPlayer.dispose();
      _restEndPlayer.dispose();
      _targetPlayer.dispose();
      _milestonePlayer.dispose();
    }
  }

  // ── Play API ───────────────────────────────────────────────────────────────
  //
  // Each method seeks to the start and resumes.  Because the source is already
  // loaded (setSource in init) and ReleaseMode.stop keeps it loaded after
  // completion, seek+resume never triggers a new setSource/prepare cycle on
  // Android — the latency is negligible and no sounds are dropped.

  /// Short click on each rep count.
  void playRepTick() {
    if (!_initialized) return;
    final p = _repPool[_repIdx];
    _repIdx = (_repIdx + 1) % _repPool.length;
    p.seek(Duration.zero);
    p.resume();
  }

  /// Intense tone played on every 10th rep (10, 20, 30, …).
  void playMilestone() {
    if (!_initialized) return;
    _milestonePlayer.seek(Duration.zero);
    _milestonePlayer.resume();
  }

  /// Played at 3 / 2 / 1 seconds remaining in rest.
  void playCountdown() {
    if (!_initialized) return;
    _countdownPlayer.seek(Duration.zero);
    _countdownPlayer.resume();
  }

  /// Played when rest ends and the next set begins.
  void playRestEnd() {
    if (!_initialized) return;
    _restEndPlayer.seek(Duration.zero);
    _restEndPlayer.resume();
  }

  /// Played once when the rep count first reaches the set target.
  void playTargetReached() {
    if (!_initialized) return;
    _targetPlayer.seek(Duration.zero);
    _targetPlayer.resume();
  }

  // ── WAV synthesis ──────────────────────────────────────────────────────────

  static Uint8List _wav({
    required int hz,
    required int ms,
    double vol = 1.0,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * ms / 1000).round();
    final dataSize   = numSamples * 2; // 16-bit mono
    final buf        = ByteData(44 + dataSize);

    _str(buf, 0,  'RIFF');
    buf.setUint32(4,  36 + dataSize, Endian.little);
    _str(buf, 8,  'WAVE');
    _str(buf, 12, 'fmt ');
    buf.setUint32(16, 16,             Endian.little);
    buf.setUint16(20, 1,              Endian.little); // PCM
    buf.setUint16(22, 1,              Endian.little); // mono
    buf.setUint32(24, sampleRate,     Endian.little);
    buf.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    buf.setUint16(32, 2,              Endian.little); // block align
    buf.setUint16(34, 16,             Endian.little); // bits per sample
    _str(buf, 36, 'data');
    buf.setUint32(40, dataSize, Endian.little);

    final fadeIn  = (numSamples * 0.08).round().clamp(1, numSamples);
    final fadeOut = (numSamples * 0.25).round().clamp(1, numSamples);

    for (var i = 0; i < numSamples; i++) {
      var amp = vol;
      if (i < fadeIn) amp *= i / fadeIn;
      final fromEnd = numSamples - i;
      if (fromEnd < fadeOut) amp *= fromEnd / fadeOut;

      final t      = i / sampleRate;
      final sample = (sin(2 * pi * hz * t) * 32767 * amp)
          .round()
          .clamp(-32768, 32767);
      buf.setInt16(44 + i * 2, sample, Endian.little);
    }

    return buf.buffer.asUint8List();
  }

  static void _str(ByteData buf, int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      buf.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}

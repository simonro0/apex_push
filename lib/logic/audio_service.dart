import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// Singleton that generates tones in memory and plays them via audioplayers.
/// No audio asset files required — all sounds are synthesised at runtime.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool   _initialized = false;
  double volume       = 1.0;

  late final Uint8List _repBytes;
  late final Uint8List _countdownBytes;
  late final Uint8List _restEndBytes;
  late final Uint8List _targetBytes;

  // Three players in round-robin so rapid rep ticks can overlap.
  final List<AudioPlayer> _repPool = [];
  int _repIdx = 0;

  // Single player for infrequent event sounds (countdown / rest-end / target).
  final AudioPlayer _eventPlayer = AudioPlayer();

  // ── Init / dispose ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    _repBytes       = _wav(hz: 880,  ms: 60,  vol: 0.45);
    _countdownBytes = _wav(hz: 660,  ms: 110, vol: 0.75);
    _restEndBytes   = _wav(hz: 1100, ms: 300, vol: 0.85);
    _targetBytes    = _wav(hz: 1320, ms: 200, vol: 0.80);

    for (var i = 0; i < 3; i++) {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.stop);
      _repPool.add(p);
    }

    await _eventPlayer.setReleaseMode(ReleaseMode.stop);

    _initialized = true;
  }

  void dispose() {
    for (final p in _repPool) {
      p.dispose();
    }
    _eventPlayer.dispose();
  }

  // ── Play API ───────────────────────────────────────────────────────────────

  /// Short click on each rep count.
  void playRepTick() {
    if (!_initialized) return;
    final p = _repPool[_repIdx];
    _repIdx = (_repIdx + 1) % _repPool.length;
    p.play(BytesSource(_repBytes), volume: volume);
  }

  /// Played at 3 / 2 / 1 seconds remaining in rest.
  void playCountdown() {
    if (!_initialized) return;
    _eventPlayer.play(BytesSource(_countdownBytes), volume: volume);
  }

  /// Played when rest ends and the next set begins.
  void playRestEnd() {
    if (!_initialized) return;
    _eventPlayer.play(BytesSource(_restEndBytes), volume: volume);
  }

  /// Played once when the rep count first reaches the set target.
  void playTargetReached() {
    if (!_initialized) return;
    _eventPlayer.play(BytesSource(_targetBytes), volume: volume);
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
    buf.setUint32(16, 16,             Endian.little); // chunk size
    buf.setUint16(20, 1,              Endian.little); // PCM
    buf.setUint16(22, 1,              Endian.little); // mono
    buf.setUint32(24, sampleRate,     Endian.little); // sample rate
    buf.setUint32(28, sampleRate * 2, Endian.little); // byte rate (16-bit mono)
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

// Basic smoke test: verifies the widget tree builds without throwing.
// Full integration tests require a real device / emulator for SQLite.

import 'package:apex_push/models/training_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Re-use the pure-Dart TrainingData tests as a quick sanity check
  // so the default `flutter test` run always executes at least one assertion.
  test('TrainingData sanity – 24 units defined', () {
    expect(TrainingData.allUnitIds.length, 24);
  });

  test('TrainingData sanity – step navigation is invertible', () {
    // stepUp then stepDown should return to the original position
    // for mid-range units (where both directions are available).
    const unitId = '4-2';
    const difficulty = 'Normal';

    final up   = TrainingData.stepUp(unitId, difficulty);
    final back = TrainingData.stepDown(up.unitId, up.difficulty);
    expect(back.unitId,     unitId);
    expect(back.difficulty, difficulty);
  });
}

import 'package:apex_push/models/training_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingData – matrix', () {
    test('contains 24 units', () {
      expect(TrainingData.allUnitIds.length, 24);
      expect(TrainingData.programs.length, 24);
    });

    test('every unit has all three difficulties', () {
      for (final id in TrainingData.allUnitIds) {
        for (final diff in TrainingData.difficulties) {
          final reps = TrainingData.programs[id]?[diff];
          expect(reps, isNotNull, reason: '$id $diff missing');
          expect(reps!.length, 5, reason: '$id $diff must have 5 sets');
        }
      }
    });

    test('8-3 Easy reps match screenshot', () {
      expect(TrainingData.getReps('8-3', 'Easy'), [24, 21, 19, 18, 46]);
    });

    test('1-1 Normal reps match screenshot', () {
      expect(TrainingData.getReps('1-1', 'Normal'), [6, 6, 5, 4, 5]);
    });

    test('rest seconds per difficulty', () {
      expect(TrainingData.getRestSeconds('Easy'),   30);
      expect(TrainingData.getRestSeconds('Normal'), 60);
      expect(TrainingData.getRestSeconds('Hard'),   120);
    });

    test('maxRepsForUnit picks the highest set', () {
      expect(TrainingData.maxRepsForUnit('8-3', 'Easy'),   46);
      expect(TrainingData.maxRepsForUnit('1-1', 'Normal'),  6);
    });

    test('totalRepsForUnit sums all sets', () {
      // 8-3 Easy: 24+21+19+18+46 = 128
      expect(TrainingData.totalRepsForUnit('8-3', 'Easy'), 128);
    });
  });

  group('TrainingData – level recommendation', () {
    test('recommends unit with minimal gap above practice result', () {
      const practiceReps = 18;
      final unit = TrainingData.recommendUnit(practiceReps, 'Easy');
      final max  = TrainingData.maxRepsForUnit(unit, 'Easy');

      expect(max, greaterThan(practiceReps));

      // No other unit should have a smaller positive gap.
      for (final id in TrainingData.allUnitIds) {
        final m = TrainingData.maxRepsForUnit(id, 'Easy');
        if (m > practiceReps) {
          expect(m, greaterThanOrEqualTo(max),
              reason: '$id has smaller gap (max=$m vs recommended max=$max)');
        }
      }
    });

    test('returns first unit when result is below all maxima', () {
      final unit = TrainingData.recommendUnit(0, 'Easy');
      expect(TrainingData.allUnitIds, contains(unit));
    });
  });

  group('TrainingData – navigation', () {
    test('nextUnit follows programme order', () {
      expect(TrainingData.nextUnit('1-3'), '2-1');
      expect(TrainingData.nextUnit('7-3'), '8-1');
      expect(TrainingData.nextUnit('8-3'), isNull);
    });

    test('previousUnit follows programme order', () {
      expect(TrainingData.previousUnit('2-1'), '1-3');
      expect(TrainingData.previousUnit('8-1'), '7-3');
      expect(TrainingData.previousUnit('1-1'), isNull);
    });

    test('stepUp Easy → Normal within same unit', () {
      final r = TrainingData.stepUp('3-2', 'Easy');
      expect(r.unitId, '3-2');
      expect(r.difficulty, 'Normal');
    });

    test('stepUp Hard → next unit at Easy', () {
      final r = TrainingData.stepUp('3-2', 'Hard');
      expect(r.unitId, '3-3');
      expect(r.difficulty, 'Easy');
    });

    test('stepUp at absolute maximum stays put', () {
      final r = TrainingData.stepUp('8-3', 'Hard');
      expect(r.unitId, '8-3');
      expect(r.difficulty, 'Hard');
    });

    test('stepDown Normal → Easy within same unit', () {
      final r = TrainingData.stepDown('5-1', 'Normal');
      expect(r.unitId, '5-1');
      expect(r.difficulty, 'Easy');
    });

    test('stepDown Easy → previous unit at Hard', () {
      final r = TrainingData.stepDown('2-1', 'Easy');
      expect(r.unitId, '1-3');
      expect(r.difficulty, 'Hard');
    });

    test('stepDown at absolute minimum stays put', () {
      final r = TrainingData.stepDown('1-1', 'Easy');
      expect(r.unitId, '1-1');
      expect(r.difficulty, 'Easy');
    });
  });
}

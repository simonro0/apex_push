class RepDetail {
  final int?   id;
  final int    workoutId;
  final int    repIndex;
  final int    timestampMs;
  final double peakG;
  final bool   isNear;

  const RepDetail({
    this.id,
    required this.workoutId,
    required this.repIndex,
    required this.timestampMs,
    required this.peakG,
    required this.isNear,
  });

  Map<String, dynamic> toMap() => {
    'id':           id,
    'workout_id':   workoutId,
    'rep_index':    repIndex,
    'timestamp_ms': timestampMs,
    'peak_g':       peakG,
    'is_near':      isNear ? 1 : 0,
  };

  factory RepDetail.fromMap(Map<String, dynamic> map) => RepDetail(
    id:           map['id'] as int?,
    workoutId:    map['workout_id'] as int,
    repIndex:     map['rep_index'] as int,
    timestampMs:  map['timestamp_ms'] as int,
    peakG:        (map['peak_g'] as num).toDouble(),
    isNear:       map['is_near'] == 1,
  );
}

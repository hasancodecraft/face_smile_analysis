import 'dart:ui';

class FaceResult {
  const FaceResult({required this.boundingBox, required this.smileProbability});

  final Rect boundingBox;
  final double? smileProbability;

  bool get isSmiling => smileProbability != null && smileProbability! >= 0.7;

  String get smileStatus => isSmiling ? 'Smiling' : 'Not Smiling';

  String get probabilityText {
    final probability = smileProbability;
    if (probability == null) return 'Unavailable';
    // Do not round a value below the threshold up to 70.0%.
    final percentage = (probability * 1000).floor() / 10;
    return '${percentage.toStringAsFixed(1)}%';
  }
}

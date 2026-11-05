import 'dart:ui';

import 'package:face_smile_analysis/features/face_detection/models/face_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FaceResult result(double? probability) => FaceResult(
    boundingBox: const Rect.fromLTWH(0, 0, 10, 10),
    smileProbability: probability,
  );

  test('the assignment threshold includes exactly 0.7', () {
    expect(result(0).isSmiling, isFalse);
    expect(result(0.6999).isSmiling, isFalse);
    expect(result(0.7).isSmiling, isTrue);
    expect(result(0.7001).isSmiling, isTrue);
    expect(result(1).isSmiling, isTrue);
  });

  test('display formatting cannot round a non-smile up to 70 percent', () {
    expect(result(0.6999).probabilityText, '69.9%');
    expect(result(0.7).probabilityText, '70.0%');
  });

  test('a missing probability is labelled rather than fabricated', () {
    expect(result(null).isSmiling, isFalse);
    expect(result(null).probabilityText, 'Unavailable');
  });
}

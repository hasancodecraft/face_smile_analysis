import 'dart:ui';

import 'package:face_smile_analysis/features/face_detection/widgets/face_image_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landscape boxes include the vertical letterbox offset', () {
    final rect = mapFaceRect(
      const Rect.fromLTWH(100, 50, 200, 100),
      const Size(1000, 500),
      const Size(300, 300),
    );
    expect(rect, const Rect.fromLTWH(30, 90, 60, 30));
  });

  test('portrait boxes include the horizontal letterbox offset', () {
    final rect = mapFaceRect(
      const Rect.fromLTWH(50, 100, 100, 200),
      const Size(500, 1000),
      const Size(300, 300),
    );
    expect(rect, const Rect.fromLTWH(90, 30, 30, 60));
  });

  test('square images need no extra offset', () {
    expect(
      mapFaceRect(
        const Rect.fromLTWH(20, 20, 40, 40),
        const Size(100, 100),
        const Size(200, 200),
      ),
      const Rect.fromLTWH(40, 40, 80, 80),
    );
  });
}

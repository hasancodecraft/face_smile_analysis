import 'dart:io';

import 'package:flutter/material.dart';

import '../models/face_result.dart';

Rect mapFaceRect(Rect face, Size imageSize, Size viewSize) {
  if (imageSize.isEmpty || viewSize.isEmpty) return Rect.zero;
  final fitted = applyBoxFit(BoxFit.contain, imageSize, viewSize);
  final imageRect = Alignment.center.inscribe(
    fitted.destination,
    Offset.zero & viewSize,
  );
  final scale = imageRect.width / imageSize.width;
  return Rect.fromLTWH(
    imageRect.left + face.left * scale,
    imageRect.top + face.top * scale,
    face.width * scale,
    face.height * scale,
  );
}

class FaceImagePreview extends StatelessWidget {
  const FaceImagePreview({
    super.key,
    required this.file,
    required this.imageSize,
    required this.faces,
  });

  final File file;
  final Size imageSize;
  final List<FaceResult> faces;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0xFFE9EEF0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                key: ValueKey(file.path),
                fit: BoxFit.contain,
                semanticLabel:
                    'Selected image with ${faces.length} detected faces',
                errorBuilder: (_, error, stack) => const Center(
                  child: Text(
                    'Could not display the image. Select another photo.',
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: FaceBoxPainter(imageSize: imageSize, faces: faces),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceBoxPainter extends CustomPainter {
  FaceBoxPainter({required this.imageSize, required this.faces});

  final Size imageSize;
  final List<FaceResult> faces;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || imageSize.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < faces.length; i++) {
      final face = faces[i];
      final rect = mapFaceRect(face.boundingBox, imageSize, size);
      final color = face.isSmiling
          ? const Color(0xFF008060)
          : const Color(0xFFB45309);
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      final label = TextPainter(
        text: TextSpan(
          text: 'Face ${i + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      if (size.width < label.width + 8 || size.height < label.height + 6) {
        label.dispose();
        continue;
      }
      final left = rect.left.clamp(
        0.0,
        (size.width - label.width - 8).clamp(0.0, size.width),
      );
      final top = (rect.top - label.height - 6).clamp(
        0.0,
        size.height - label.height - 6,
      );
      canvas.drawRect(
        Rect.fromLTWH(left, top, label.width + 8, label.height + 6),
        Paint()..color = color,
      );
      label.paint(canvas, Offset(left + 4, top + 3));
      label.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter oldDelegate) =>
      oldDelegate.imageSize != imageSize || oldDelegate.faces != faces;
}

import 'package:flutter/material.dart';

import '../models/face_result.dart';

class FaceInfoCard extends StatelessWidget {
  const FaceInfoCard({super.key, required this.faceNumber, required this.face});

  final int faceNumber;
  final FaceResult face;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Face $faceNumber',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Smile Status: ${face.smileStatus}'),
            const SizedBox(height: 6),
            Text('Smile Probability: ${face.probabilityText}'),
            if (face.smileProbability == null) ...[
              const SizedBox(height: 6),
              const Text('Smile data is unavailable for this face.'),
            ],
          ],
        ),
      ),
    );
  }
}

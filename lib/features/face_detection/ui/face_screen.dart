import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/face_provider.dart';
import '../widgets/analysis_card.dart';
import '../widgets/face_image_preview.dart';
import '../widgets/face_info_card.dart';

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<FaceProvider>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text(
          'Face Detection & Smile Analysis',
          maxLines: 2,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Choose a photo from your gallery, then tap Analyze.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: scan.isBusy ? null : scan.pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        scan.selectedImage == null
                            ? 'Upload Image'
                            : 'Upload Another Image',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: scan.isBusy || scan.selectedImage == null
                          ? null
                          : scan.analyze,
                      icon: const Icon(Icons.face_outlined),
                      label: const Text('Analyze'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (scan.isBusy) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                if (scan.error != null) ...[
                  Text(
                    scan.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (scan.selectedImage != null && scan.imageSize != null)
                  FaceImagePreview(
                    file: scan.selectedImage!,
                    imageSize: scan.imageSize!,
                    faces: scan.faces,
                  )
                else
                  const SizedBox(
                    height: 220,
                    child: Card(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 48),
                            SizedBox(height: 12),
                            Text('No image selected'),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final count = AnalysisCard(
                      title: 'Total Faces',
                      value: scan.hasResult ? '${scan.totalFaces}' : '—',
                    );
                    final percentage = AnalysisCard(
                      title: 'Smiling Percentage',
                      value: scan.hasResult ? scan.smilingPercentageText : '—',
                    );
                    if (constraints.maxWidth < 340 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          count,
                          const SizedBox(height: 12),
                          percentage,
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: count),
                          const SizedBox(width: 12),
                          Expanded(child: percentage),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Individual Face Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (!scan.hasResult)
                  const Text('Face details will appear after analysis.')
                else if (scan.faces.isEmpty)
                  const Text('No faces detected. Try another photo.')
                else
                  for (var i = 0; i < scan.faces.length; i++)
                    FaceInfoCard(faceNumber: i + 1, face: scan.faces[i]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

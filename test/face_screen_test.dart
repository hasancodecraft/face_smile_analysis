import 'package:face_smile_analysis/features/face_detection/providers/face_provider.dart';
import 'package:face_smile_analysis/features/face_detection/ui/face_screen.dart';
import 'package:face_smile_analysis/features/face_detection/widgets/face_image_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fakes.dart';

void main() {
  late FaceProvider provider;
  late FakeDetector detector;

  setUp(() {
    detector = FakeDetector();
    provider = FaceProvider(FakePicker(), detector: detector);
  });

  tearDown(() => provider.dispose());

  Widget screen({double textScale = 1}) => ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const FaceScreen(),
    ),
  );

  testWidgets('the home screen exposes the required controls and cards', (
    tester,
  ) async {
    await tester.pumpWidget(screen());
    expect(find.text('Face Detection & Smile Analysis'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Total Faces'), findsOneWidget);
    expect(find.text('Smiling Percentage'), findsOneWidget);
    final analyze = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Analyze'),
    );
    expect(analyze.onPressed, isNull);
  });

  testWidgets('multiple faces render matching boxes and individual details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    detector.result = [0.9, 0.85, 0.7, 0.2].map(sampleFace).toList();
    await tester.runAsync(() async {
      await provider.pickImage();
      await provider.analyze();
    });
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Smile Status: Smiling'), findsNWidgets(3));
    expect(find.text('Smile Status: Not Smiling'), findsOneWidget);
    expect(find.text('Smile Probability: 70.0%'), findsOneWidget);
    expect(find.text('Face 4'), findsOneWidget);
    expect(find.text('Upload Another Image'), findsOneWidget);
    final preview = tester.widget<FaceImagePreview>(
      find.byType(FaceImagePreview),
    );
    expect(preview.faces.length, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a no-face result displays zero and a useful empty state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await provider.pickImage();
      await provider.analyze();
    });
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('No faces detected. Try another photo.'), findsOneWidget);
  });

  testWidgets(
    'a narrow screen and larger text remain scrollable without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(screen(textScale: 1.6));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.text('Individual Face Information'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

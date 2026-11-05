import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:face_smile_analysis/features/face_detection/providers/face_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakePicker picker;
  late FakeDetector detector;
  late FaceProvider provider;
  var disposed = false;

  setUp(() {
    picker = FakePicker();
    detector = FakeDetector();
    provider = FaceProvider(picker, detector: detector);
    disposed = false;
  });

  tearDown(() async {
    if (!disposed) provider.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'four faces with three smiles produce 75 percent, not an average',
    () async {
      detector.result = [0.90, 0.85, 0.70, 0.20].map(sampleFace).toList();
      await provider.pickImage();
      await provider.analyze();
      expect(provider.totalFaces, 4);
      expect(provider.smilingFaces, 3);
      expect(provider.smilingPercentage, 75);
      expect(provider.smilingPercentageText, '75%');
      expect(provider.hasResult, isTrue);
      expect(detector.receivedPath, provider.selectedImage!.path);
      expect(detector.receivedPath, isNot(picker.nextImage!.path));
    },
  );

  test('no faces is a successful result with zero percent', () async {
    await provider.pickImage();
    await provider.analyze();
    expect(provider.hasResult, isTrue);
    expect(provider.totalFaces, 0);
    expect(provider.smilingPercentageText, '0%');
    expect(provider.error, isNull);
  });

  test('unavailable smile data still counts in the total faces', () async {
    detector.result = [sampleFace(0.9), sampleFace(null), sampleFace(0.2)];
    await provider.pickImage();
    await provider.analyze();
    expect(provider.totalFaces, 3);
    expect(provider.smilingFaces, 1);
    expect(provider.smilingPercentageText, '33.3%');
  });

  test(
    'cancel keeps the current image and results; replacement clears them',
    () async {
      detector.result = [sampleFace(0.9)];
      await provider.pickImage();
      await provider.analyze();
      final previousPath = provider.selectedImage!.path;
      picker.nextImage = null;
      await provider.pickImage();
      expect(provider.selectedImage!.path, previousPath);
      expect(provider.totalFaces, 1);
      expect(provider.hasResult, isTrue);

      picker.nextImage = File('test/fixtures/sample.png');
      await provider.pickImage();
      expect(provider.selectedImage!.path, isNot(previousPath));
      expect(provider.faces, isEmpty);
      expect(provider.hasResult, isFalse);
    },
  );

  test(
    'EXIF rotation is normalized before both preview and detection',
    () async {
      picker.nextImage = File('test/fixtures/rotated.jpg');
      await provider.pickImage();
      expect(provider.error, isNull);
      expect(provider.imageSize, const Size(80, 120));
      expect(provider.selectedImage!.path, endsWith('.png'));
      final codec = await instantiateImageCodec(
        await provider.selectedImage!.readAsBytes(),
      );
      final image = (await codec.getNextFrame()).image;
      expect(
        Size(image.width.toDouble(), image.height.toDouble()),
        provider.imageSize,
      );
      image.dispose();
      codec.dispose();
      expect(await picker.nextImage!.exists(), isTrue);
    },
  );

  test('failed image loading leaves the previous valid image intact', () async {
    await provider.pickImage();
    final previous = provider.selectedImage;
    picker.nextImage = File('test/fixtures/does_not_exist.jpg');
    await provider.pickImage();
    expect(provider.selectedImage, same(previous));
    expect(provider.error, isNotNull);
    expect(provider.isBusy, isFalse);
  });

  test(
    'analysis errors can be retried without showing stale results',
    () async {
      await provider.pickImage();
      detector.fail = true;
      await provider.analyze();
      expect(provider.hasResult, isFalse);
      expect(provider.faces, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.isBusy, isFalse);
      detector.fail = false;
      detector.result = [sampleFace(0.8)];
      await provider.analyze();
      expect(provider.error, isNull);
      expect(provider.smilingPercentage, 100);
    },
  );

  test(
    'an active scan prevents duplicate analysis and image replacement',
    () async {
      await provider.pickImage();
      detector.pending = Completer<List<Face>>();
      final scan = provider.analyze();
      await provider.analyze();
      await provider.pickImage();
      expect(detector.calls, 1);
      expect(picker.calls, 1);
      expect(provider.isBusy, isTrue);
      detector.pending!.complete([sampleFace(0.8)]);
      await scan;
      expect(provider.totalFaces, 1);
    },
  );

  test(
    'dispose waits for native analysis before closing the detector',
    () async {
      await provider.pickImage();
      detector.pending = Completer<List<Face>>();
      final scan = provider.analyze();
      provider.dispose();
      disposed = true;
      expect(detector.closed, isFalse);
      detector.pending!.complete([sampleFace(0.8)]);
      await scan;
      await Future<void>.delayed(Duration.zero);
      expect(detector.closed, isTrue);
    },
  );

  test('a recovered Android picker image can be analyzed normally', () async {
    picker.lostImage = File('test/fixtures/sample.png');
    await provider.restoreLostImage();
    expect(provider.selectedImage, isNotNull);
    expect(provider.hasResult, isFalse);
    await provider.analyze();
    expect(provider.hasResult, isTrue);
  });

  test(
    'the real plugin receives classification options and the prepared path',
    () async {
      const channel = MethodChannel('google_mlkit_face_detector');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Map<dynamic, dynamic>? arguments;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'vision#startFaceDetector') {
          arguments = call.arguments as Map<dynamic, dynamic>;
          return [
            {
              'rect': {'left': 5.0, 'top': 5.0, 'right': 20.0, 'bottom': 30.0},
              'smilingProbability': 0.7,
              'landmarks': <String, dynamic>{},
              'contours': <String, dynamic>{},
            },
          ];
        }
        return null;
      });
      final realProvider = FaceProvider(FakePicker());
      await realProvider.pickImage();
      await realProvider.analyze();
      expect(arguments!['options']['enableClassification'], isTrue);
      expect(arguments!['options']['enableContours'], isFalse);
      expect(arguments!['imageData']['path'], realProvider.selectedImage!.path);
      expect(realProvider.smilingFaces, 1);
      realProvider.dispose();
      await Future<void>.delayed(Duration.zero);
      messenger.setMockMethodCallHandler(channel, null);
    },
  );
}

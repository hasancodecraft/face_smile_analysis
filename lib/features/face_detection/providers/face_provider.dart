import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/services/image_picker_service.dart';
import '../models/face_result.dart';

class FaceProvider extends ChangeNotifier {
  FaceProvider(this._picker, {FaceDetector? detector})
    : _detector =
          detector ??
          FaceDetector(
            options: FaceDetectorOptions(
              enableClassification: true,
              enableLandmarks: true,
              performanceMode: FaceDetectorMode.accurate,
              minFaceSize: 0.05,
            ),
          );

  final ImagePickerService _picker;
  final FaceDetector _detector;
  File? selectedImage;
  ui.Size? imageSize;
  List<FaceResult> faces = [];
  bool isBusy = false;
  bool hasResult = false;
  String? error;

  bool _disposed = false;
  Directory? _workingDirectory;
  Future<void>? _pendingOperation;
  int _imageNumber = 0;

  int get totalFaces => faces.length;
  int get smilingFaces => faces.where((face) => face.isSmiling).length;
  double get smilingPercentage =>
      totalFaces == 0 ? 0 : smilingFaces / totalFaces * 100;

  String get smilingPercentageText {
    final value = smilingPercentage;
    final digits = value == value.roundToDouble() ? 0 : 1;
    return '${value.toStringAsFixed(digits)}%';
  }

  Future<void> pickImage() => _selectImage();

  Future<void> restoreLostImage() => _selectImage(restore: true);

  Future<void> _selectImage({bool restore = false}) async {
    if (isBusy || _disposed) return;
    isBusy = true;
    error = null;
    notifyListeners();
    _pendingOperation = _pickAndPrepare(restore);
    await _pendingOperation;
  }

  Future<void> _pickAndPrepare(bool restore) async {
    try {
      final file = restore
          ? await _picker.retrieveLostImage()
          : await _picker.pickImage();
      if (file == null || _disposed) return;
      await _prepareImage(file);
    } catch (_) {
      if (!_disposed) {
        error = 'Could not open the image. Please select another photo.';
      }
    } finally {
      _finishOperation();
    }
  }

  Future<void> _prepareImage(File file) async {
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    ui.Image? decodedImage;
    try {
      decodedImage = (await codec.getNextFrame()).image;
      final data = await decodedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (data == null) throw StateError('The image could not be decoded.');
      if (_disposed) return;

      // Preview and detection use the same decoded pixels and orientation.
      _workingDirectory ??= await Directory.systemTemp.createTemp(
        'smile_analysis_',
      );
      final prepared = File(
        '${_workingDirectory!.path}/image_${_imageNumber++}.png',
      );
      await prepared.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      if (_disposed) return;

      selectedImage = prepared;
      imageSize = ui.Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
      faces = [];
      hasResult = false;
    } finally {
      decodedImage?.dispose();
      codec.dispose();
    }
  }

  Future<void> analyze() async {
    if (isBusy || _disposed || selectedImage == null) return;
    isBusy = true;
    hasResult = false;
    faces = [];
    error = null;
    notifyListeners();
    _pendingOperation = _processImage();
    await _pendingOperation;
  }

  Future<void> _processImage() async {
    try {
      final input = InputImage.fromFilePath(selectedImage!.path);
      final detectedFaces = await _detector.processImage(input);
      if (_disposed) return;
      faces = detectedFaces
          .map(
            (face) => FaceResult(
              boundingBox: face.boundingBox,
              smileProbability: face.smilingProbability,
            ),
          )
          .toList();
      hasResult = true;
    } catch (_) {
      if (!_disposed) {
        error = 'Analysis failed. Please try again with a clear photo.';
      }
    } finally {
      _finishOperation();
    }
  }

  void _finishOperation() {
    if (_disposed) return;
    isBusy = false;
    notifyListeners();
  }

  Future<void> _releaseResources() async {
    try {
      await (_pendingOperation ?? Future<void>.value());
      await _detector.close();
    } finally {
      final directory = _workingDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    // A running scan must finish before its native detector is closed.
    unawaited(
      _releaseResources().catchError((Object error) {
        debugPrint('Face detector cleanup failed: $error');
      }),
    );
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';

import 'package:face_smile_analysis/core/services/image_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FakePicker extends ImagePickerService {
  File? nextImage = File('test/fixtures/sample.png');
  File? lostImage;
  int calls = 0;

  @override
  Future<File?> pickImage() async {
    calls++;
    return nextImage;
  }

  @override
  Future<File?> retrieveLostImage() async => lostImage;
}

class FakeDetector extends FaceDetector {
  FakeDetector() : super(options: FaceDetectorOptions());

  List<Face> result = [];
  Completer<List<Face>>? pending;
  bool fail = false;
  bool closed = false;
  int calls = 0;
  String? receivedPath;

  @override
  Future<List<Face>> processImage(InputImage inputImage) async {
    calls++;
    receivedPath = inputImage.filePath;
    if (fail) throw StateError('Test detection failure');
    return pending == null ? result : await pending!.future;
  }

  @override
  Future<void> close() async => closed = true;
}

Face sampleFace(double? probability) => Face(
  boundingBox: const Rect.fromLTWH(10, 10, 30, 40),
  smilingProbability: probability,
  landmarks: {},
  contours: {},
);

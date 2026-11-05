import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/image_picker_service.dart';
import 'features/face_detection/providers/face_provider.dart';
import 'features/face_detection/ui/face_screen.dart';

class FaceSmileApp extends StatelessWidget {
  const FaceSmileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceProvider(ImagePickerService())..restoreLostImage(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Face Detection & Smile Analysis',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
          scaffoldBackgroundColor: const Color(0xFFF5F7F8),
          useMaterial3: true,
        ),
        home: const FaceScreen(),
      ),
    );
  }
}

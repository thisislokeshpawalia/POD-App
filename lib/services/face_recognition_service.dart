import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  Interpreter? _interpreter;
  late final FaceDetector _faceDetector;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/models/mobile_face_net.tflite', options: options);
      
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
        ),
      );
      
      _isInitialized = true;
      debugPrint('Face Recognition initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Face Recognition: $e');
    }
  }

  Future<List<double>?> getEmbedding(String imagePath) async {
    if (!_isInitialized) await initialize();
    if (_interpreter == null) {
      throw Exception('TFLite Interpreter is null. Model failed to load.');
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file does not exist at path: $imagePath');
    }

    final inputImage = InputImage.fromFile(file);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      throw Exception('No face detected in the image');
    }

    // Get largest face by bounding box area
    faces.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB.compareTo(areaA);
    });
    final face = faces.first;

    // Load full image using image package
    final imageBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Could not decode image');

    // Crop face
    final bbox = face.boundingBox;
    
    // Add some padding to the bounding box
    final w = bbox.width;
    final h = bbox.height;
    final l = max(0, bbox.left - w * 0.1).toInt();
    final t = max(0, bbox.top - h * 0.1).toInt();
    final r = min(image.width, bbox.right + w * 0.1).toInt();
    final b = min(image.height, bbox.bottom + h * 0.1).toInt();
    
    img.Image croppedFace = img.copyCrop(
      image,
      x: l,
      y: t,
      width: r - l,
      height: b - t,
    );

    // Resize to 112x112
    img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

    // Convert to Float32 1x112x112x3 tensor
    var input = List.generate(
      1,
      (i) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = resizedFace.getPixel(x, y);
            return [
              (pixel.r - 127.5) / 127.5,
              (pixel.g - 127.5) / 127.5,
              (pixel.b - 127.5) / 127.5,
            ];
          },
        ),
      ),
    );

    // Output tensor for MobileFaceNet is usually [1, 192]
    var output = List.generate(1, (i) => List.filled(192, 0.0));

    // Run inference
    _interpreter!.run(input, output);

    return output[0];
  }

  double _euclideanDistance(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      final diff = e1[i] - e2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Verifies if two images contain the same person.
  Future<bool> verifyFaces(String imagePath1, String imagePath2) async {
    final emb1 = await getEmbedding(imagePath1);
    if (emb1 == null) throw Exception('Failed to extract embedding from image 1 ($imagePath1)');
    
    final emb2 = await getEmbedding(imagePath2);
    if (emb2 == null) throw Exception('Failed to extract embedding from image 2 ($imagePath2)');

    final distance = _euclideanDistance(emb1, emb2);
    debugPrint('Face Euclidean Distance: $distance');
    
    // Threshold is typically around 1.0 to 1.1 for MobileFaceNet L2 distance
    return distance < 1.15;
  }
}

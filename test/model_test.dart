
import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

void main() {
  test('Check model input', () async {
    final interpreter = await Interpreter.fromFile(File('assets/models/mobile_face_net.tflite'));
    final inputTensor = interpreter.getInputTensor(0);
    print('Input shape: \');
    print('Input type: \');
    final outputTensor = interpreter.getOutputTensor(0);
    print('Output shape: \');
    print('Output type: \');
  });
}


import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final interpreter = await Interpreter.fromFile(File('assets/models/mobile_face_net.tflite'));
    print('Model loaded');
    var input = List.generate(1, (i) => List.generate(112, (y) => List.generate(112, (x) => [0.0, 0.0, 0.0])));
    var output = List.generate(1, (i) => List.filled(192, 0.0));
    interpreter.run(input, output);
    print('Output:');
    print(output[0].sublist(0, 10));
    exit(0);
  } catch(e) {
    print(e);
    exit(1);
  }
}

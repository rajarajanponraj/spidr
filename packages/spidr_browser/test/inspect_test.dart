import 'dart:mirrors';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

void main() {
  final roClass = reflectClass(RemoteObject);
  print('RemoteObject fields/getters:');
  roClass.declarations.forEach((key, value) {
    final isGetter = value is MethodMirror && value.isGetter;
    final isVar = value is VariableMirror;
    if (isVar || isGetter) {
      print('  ${MirrorSystem.getName(key)}');
    }
  });
}

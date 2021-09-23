import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';

void main() {
  const MethodChannel channel = MethodChannel('mindbox.cloud/flutter-sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '1.1.0';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Mindbox.instance.sdkVersion, '1.1.0');
  });
}

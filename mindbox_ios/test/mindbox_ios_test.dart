import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  const MethodChannel channel = MethodChannel('mindbox.cloud/flutter-sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxIosPlatform.registerPlatform();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '1.2.0';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MindboxPlatform.instance.sdkVersion, '1.2.0');
  });
}

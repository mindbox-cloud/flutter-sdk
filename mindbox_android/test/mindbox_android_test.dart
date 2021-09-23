import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  const MethodChannel channel = MethodChannel('mindbox.cloud/flutter-sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxAndroidPlatform.registerPlatform();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '1.1.0';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MindboxPlatform.instance.sdkVersion, '1.1.0');
  });
}

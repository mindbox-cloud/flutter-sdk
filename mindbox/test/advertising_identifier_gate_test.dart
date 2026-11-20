import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/src/advertising_identifier_gate.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idfa = 'EA7583CD-A667-48BC-B806-42ECB2B48606';
  late List<Object?> identifiersPassedToIosSdk;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    MindboxIosPlatform.registerPlatform();
    identifiersPassedToIosSdk = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setAdvertisingIdentifier') {
        identifiersPassedToIosSdk.add(call.arguments);
      }
      return mindboxMockMethodCallHandler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
      'An identifier set before init is held, so with disableTrackingIds the '
      'IDFA never reaches the iOS SDK', () async {
    final gate = AdvertisingIdentifierGate();

    gate.setAdvertisingIdentifier(idfa);
    gate.init(disableTrackingIds: true);
    await pumpEventQueue();

    expect(identifiersPassedToIosSdk, [null]);
  });

  test(
      'An identifier held before init reaches the iOS SDK once init leaves '
      'tracking ids on', () async {
    final gate = AdvertisingIdentifierGate();

    gate.setAdvertisingIdentifier(idfa);
    gate.init(disableTrackingIds: false);
    await pumpEventQueue();

    expect(identifiersPassedToIosSdk, [idfa]);
  });

  test(
      'Only the last identifier set before init is passed on, so a withdrawn '
      'consent reaches the iOS SDK as null', () async {
    final gate = AdvertisingIdentifierGate();

    gate.setAdvertisingIdentifier(idfa);
    gate.setAdvertisingIdentifier(null);
    gate.init(disableTrackingIds: false);
    await pumpEventQueue();

    expect(identifiersPassedToIosSdk, [null]);
  });
}

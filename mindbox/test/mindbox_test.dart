import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';
import 'package:mindbox_android/mindbox_android.dart';
import 'package:mindbox_ios/mindbox_ios.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

// ignore_for_file: unchecked_use_of_nullable_value
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxIosPlatform.registerPlatform();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, mindboxMockMethodCallHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await Mindbox.instance.nativeSdkVersion, 'dummy-sdk-version');
  });

  test('init()', () async {
    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    Mindbox.instance.init(configuration: validConfig);
  });

  test('When SDK was initialized, getDeviceUUID() should return device uuid',
      () async {
    final completer = Completer<String>();

    Mindbox.instance.getDeviceUUID((uuid) => completer.complete(uuid));

    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    Mindbox.instance.init(configuration: validConfig);

    expect(await completer.future, equals('dummy-device-uuid'));
  });

  test(
      'When SDK was not initialized, getDeviceUUID() should not return '
      'device uuid', () async {
    final completer = Completer<String>();

    Mindbox.instance.getDeviceUUID((uuid) => completer.complete(uuid));

    expect(completer.isCompleted, isFalse);
  });

  test('When SDK was initialized, getToken() should return token', () async {
    final completer = Completer<String>();

    Mindbox.instance.getToken((deviceToken) => completer.complete(deviceToken));

    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    Mindbox.instance.init(configuration: validConfig);

    expect(await completer.future, equals('dummy-token'));
  });

  test('When SDK was initialized, getTokens() should return tokens', () async {
    final completer = Completer<String>();

    Mindbox.instance.getTokens((deviceToken) => completer.complete(deviceToken));

    final validConfig = Configuration(
        domain: 'domain',
        endpointIos: 'endpointIos',
        endpointAndroid: 'endpointAndroid',
        subscribeCustomerIfCreated: true);

    Mindbox.instance.init(configuration: validConfig);

    expect(await completer.future, equals('dummy-tokens'));
  });

  test('When SDK was not initialized, getToken() should not return token',
      () async {
    final completer = Completer<String>();

    Mindbox.instance.getTokens((deviceToken) => completer.complete(deviceToken));

    expect(completer.isCompleted, isFalse);
  });

  test('onPushClickReceived()', () async {
    StubMindboxPlatform.registerPlatform();
    final completer = Completer<List<String>>();

    Mindbox.instance.onPushClickReceived(
        (url, payload) => completer.complete([url, payload]));

    expect(await completer.future, equals(['dummy-url', 'dummy-payload']));
  });

  const idfa = 'EA7583CD-A667-48BC-B806-42ECB2B48606';

  Configuration configuration({bool? disableTrackingIds}) => Configuration(
      domain: 'domain',
      endpointIos: 'endpointIos',
      endpointAndroid: 'endpointAndroid',
      subscribeCustomerIfCreated: true,
      disableTrackingIds: disableTrackingIds);

  List<MethodCall> recordChannelCalls(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return mindboxMockMethodCallHandler(call);
    });
    return calls;
  }

  List<String> initAndIdentifierCalls(List<MethodCall> calls) => [
        for (final call in calls)
          if (call.method == 'init')
            'init'
          else if (call.method == 'setAdvertisingIdentifier')
            'setAdvertisingIdentifier(${call.arguments})'
      ];

  test('setAdvertisingIdentifier() passes the identifier to the iOS SDK',
      () async {
    final calls = recordChannelCalls(TargetPlatform.iOS);

    Mindbox.instance.init(configuration: configuration());
    await pumpEventQueue();
    Mindbox.instance.setAdvertisingIdentifier(idfa);
    await pumpEventQueue();

    expect(initAndIdentifierCalls(calls),
        ['init', 'setAdvertisingIdentifier($idfa)']);
  });

  test(
      'When disableTrackingIds is true, setAdvertisingIdentifier() passes '
      'null to the iOS SDK', () async {
    final calls = recordChannelCalls(TargetPlatform.iOS);

    Mindbox.instance
        .init(configuration: configuration(disableTrackingIds: true));
    await pumpEventQueue();
    calls.clear();
    Mindbox.instance.setAdvertisingIdentifier(idfa);
    await pumpEventQueue();

    expect(initAndIdentifierCalls(calls), ['setAdvertisingIdentifier(null)']);
  });

  test(
      'When disableTrackingIds is true, init() clears the identifier in the '
      'iOS SDK before the native initialization', () async {
    final calls = recordChannelCalls(TargetPlatform.iOS);

    Mindbox.instance
        .init(configuration: configuration(disableTrackingIds: true));
    await pumpEventQueue();

    expect(initAndIdentifierCalls(calls),
        ['setAdvertisingIdentifier(null)', 'init']);
  });

  test('On Android the identifier never reaches the native SDK', () async {
    MindboxAndroidPlatform.registerPlatform();
    final calls = recordChannelCalls(TargetPlatform.android);

    Mindbox.instance
        .init(configuration: configuration(disableTrackingIds: true));
    Mindbox.instance.setAdvertisingIdentifier(idfa);
    await pumpEventQueue();

    expect(initAndIdentifierCalls(calls), ['init']);
  });
}

class StubMindboxPlatform extends MindboxPlatform {
  StubMindboxPlatform._();

  static void registerPlatform() {
    MindboxPlatform.instance = StubMindboxPlatform._();
  }

  @override
  void onPushClickReceived({
    required PushClickHandler handler,
  }) {
    handler('dummy-url', 'dummy-payload');
  }
}

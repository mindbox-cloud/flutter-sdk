import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';
import 'package:mindbox_ios/mindbox_ios.dart';

void main() {
  const MethodChannel channel = MethodChannel('mindbox.cloud/flutter-sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MindboxIosPlatform.registerPlatform();
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getSdkVersion':
          return '1.1.0';
        default:
          return 'any string';
      }
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getSdkVersion', () async {
    expect(await Mindbox.instance.sdkVersion, '1.1.0');
  });

  test('init', () async {
    final Configuration configuration = Configuration(
        domain: '',
        endpointIos: '',
        endpointAndroid: '',
        subscribeCustomerIfCreated: true);

    await Mindbox.instance.init(configuration: configuration);


    // expect(myAsyncFunction('Test input'), throwsA(isA<MindboxException>()));
    // Future<String> myAsyncFunction(String input) async {
    //   final String result =
    //       await Future<String>.delayed(const Duration(seconds: 1), () async {
    //     await Mindbox.instance.init(configuration: configuration);
    //     return '123';
    //     // throw MindboxException(message: '123');
    //   });
    //   return result;
    // }
    //
    // expect(() async => Mindbox.instance.init(configuration: configuration),
    //     throwsA(isA<MindboxException>()));
    Mindbox.instance
        .init(configuration: configuration)
        .then((value) => print('hello'))
        .onError((error, stackTrace) => print(error));



    expectSync(
            () async => await Mindbox.instance.init(configuration: configuration),
        throwsA(isA<MindboxException>()));
    // expect(() => myAsyncFunction('123'), throwsA(isA<MindboxException>()));
  });

  // test('getDeviceUUID()', () async {
  //   final Configuration configuration = Configuration(
  //       domain: '',
  //       endpointIos: '',
  //       endpointAndroid: '',
  //       subscribeCustomerIfCreated: true);
  //   await Mindbox.instance.init(configuration: configuration);
  //
  //   Mindbox.instance.getDeviceUUID((token) {
  //     expect(token, 'any string');
  //   });
  // });

  // test('getToken()', () async {
  //   final Configuration configuration = Configuration(
  //       domain: '',
  //       endpointIos: '',
  //       endpointAndroid: '',
  //       subscribeCustomerIfCreated: true);
  //   await Mindbox.instance.init(configuration: configuration);
  //
  //   Mindbox.instance.getToken((token) {
  //     expect(token, 'any string');
  //   });
  // });
}

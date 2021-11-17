import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$MindboxPlatform', () {
    test('Can be extended', () {
      MindboxPlatform.instance = ExtendsMindboxPlatform();
    });

    final MindboxPlatform mindboxPlatform = ExtendsMindboxPlatform();

    test(
        'Default implementation of sdkVersion should throw unimplemented error',
        () {
      expect(
        () => mindboxPlatform.sdkVersion,
        throwsUnimplementedError,
      );
    });

    test('Default implementation of init() should throw unimplemented error',
        () {
      expect(
        () => mindboxPlatform.init(
            configuration: Configuration(
          endpointAndroid: 'test',
          endpointIos: 'test',
          domain: 'test',
          subscribeCustomerIfCreated: true,
        )),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getDeviceUUID() '
        'should throw unimplemented error', () {
      expect(
        () => mindboxPlatform.getDeviceUUID(callback: (uuid) {}),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of getToken() should throw unimplemented error',
        () {
      expect(
        () => mindboxPlatform.getToken(callback: (token) {}),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of onPushClickReceived() '
        'should throw unimplemented error', () {
      expect(
        () => mindboxPlatform.onPushClickReceived(callback: (link) {}),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of executeAsyncOperation() '
        'should throw unimplemented error', () {
      expect(
        () => mindboxPlatform.executeAsyncOperation(
            operationSystemName: 'dummy-name',
            operationBody: {'dummy-key': 'dummy-value'}),
        throwsUnimplementedError,
      );
    });

    test(
        'Default implementation of executeSyncOperation() '
        'should throw unimplemented error', () {
      expect(
        () => mindboxPlatform.executeSyncOperation(
          operationSystemName: 'dummy-name',
          operationBody: {'dummy-key': 'dummy-value'},
          onSuccess: (success) {},
          onError: (error) {},
        ),
        throwsUnimplementedError,
      );
    });
  });
}

class ExtendsMindboxPlatform extends MindboxPlatform {}

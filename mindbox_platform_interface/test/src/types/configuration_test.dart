import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/src/types/configuration.dart';

void main() {
  test('Constructor Test', () {
    final Configuration configuration = Configuration(
      domain: 'domain',
      endpointIos: 'iOsEndpoint',
      endpointAndroid: 'androidEndpoint',
      previousInstallationId: 'previousInstallationId',
      previousDeviceUUID: 'previousDeviceUUID',
      subscribeCustomerIfCreated: true,
      shouldCreateCustomer: true,
    );

    expect(configuration.domain, 'domain');
    expect(configuration.endpointIos, 'iOsEndpoint');
    expect(configuration.endpointAndroid, 'androidEndpoint');
    expect(configuration.previousInstallationId, 'previousInstallationId');
    expect(configuration.previousDeviceUUID, 'previousDeviceUUID');
    expect(configuration.subscribeCustomerIfCreated, true);
    expect(configuration.shouldCreateCustomer, true);
  });
}

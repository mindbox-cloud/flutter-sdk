import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/src/types/configuration.dart';

void main() {
  test('Constructor Test', () {
    // Arrange
    final Configuration configuration = Configuration(
      domain: 'domain',
      endpointIos: 'iOSEndpoint',
      endpointAndroid: 'androidEndpoint',
      previousInstallationId: 'previousInstallationId',
      previousDeviceUUID: 'previousDeviceUUID',
      subscribeCustomerIfCreated: true,
      shouldCreateCustomer: true,
      operationsDomain: 'operations.example.com',
    );

    // Assert
    expect(configuration.domain, 'domain');
    expect(configuration.endpointIos, 'iOSEndpoint');
    expect(configuration.endpointAndroid, 'androidEndpoint');
    expect(configuration.previousInstallationId, 'previousInstallationId');
    expect(configuration.previousDeviceUUID, 'previousDeviceUUID');
    expect(configuration.subscribeCustomerIfCreated, true);
    expect(configuration.shouldCreateCustomer, true);
    expect(configuration.operationsDomain, 'operations.example.com');
  });

  test('operationsDomain defaults to empty string when not provided', () {
    final Configuration configuration = Configuration(
      domain: 'domain',
      endpointIos: 'iOSEndpoint',
      endpointAndroid: 'androidEndpoint',
    );

    expect(configuration.operationsDomain, '');
  });

  test('toMap includes operationsDomain when set', () {
    final Configuration configuration = Configuration(
      domain: 'domain',
      endpointIos: 'iOSEndpoint',
      endpointAndroid: 'androidEndpoint',
      operationsDomain: 'operations.example.com',
    );

    expect(configuration.toMap()['operationsDomain'], 'operations.example.com');
  });

  test('toMap returns empty operationsDomain when not provided', () {
    final Configuration configuration = Configuration(
      domain: 'domain',
      endpointIos: 'iOSEndpoint',
      endpointAndroid: 'androidEndpoint',
    );

    expect(configuration.toMap()['operationsDomain'], '');
  });
}

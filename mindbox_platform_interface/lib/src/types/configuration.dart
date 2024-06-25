/// The class represents the information for SDK initialization.
class Configuration {
  /// Constructs a Configuration.
  Configuration({
    required this.domain,
    required this.endpointIos,
    required this.endpointAndroid,
    this.subscribeCustomerIfCreated = false,
    this.previousDeviceUUID = '',
    this.previousInstallationId = '',
    this.shouldCreateCustomer = true,
  });

  /// Used for generating baseurl for REST.
  final String domain;

  /// Used for app identification on iOS.
  final String endpointIos;

  /// Used for app identification on Android.
  final String endpointAndroid;

  /// Flag which determines subscription status of the user.
  final bool subscribeCustomerIfCreated;

  /// Used instead of the generated value on native platform.
  final String previousDeviceUUID;

  /// Used to create tracking continuity by uuid.
  final String previousInstallationId;

  /// Flag which determines create or not anonymous users. Usable only during
  /// first initialisation. Default is `true`.
  final bool shouldCreateCustomer;

  /// Returns map of parameters
  Map<String, dynamic> toMap() => {
        'domain': domain,
        'endpointIos': endpointIos,
        'endpointAndroid': endpointAndroid,
        'previousDeviceUUID': previousDeviceUUID,
        'previousInstallationId': previousInstallationId,
        'subscribeCustomerIfCreated': subscribeCustomerIfCreated,
        'shouldCreateCustomer': shouldCreateCustomer,
      };
}

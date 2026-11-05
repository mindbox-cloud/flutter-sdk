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
    this.operationsDomain = '',
    this.shouldIncludeVersionCode,
    this.disableTrackingIds,
  });

  /// Used for generating baseurl for REST.
  final String domain;

  /// Optional separate host for sending operations. When empty, [domain]
  /// is used. Default is an empty string.
  final String operationsDomain;

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

  /// Specifies whether the app versionCode is included in the app version
  /// reported to Mindbox. When `false`, only versionName is reported.
  /// Android only, ignored on iOS.
  ///
  /// When not provided, the key is not sent to the native SDK and its
  /// default is used (`true` — versionCode is reported).
  final bool? shouldIncludeVersionCode;

  /// Turns off the collection of the device tracking identifier (GAID from
  /// Google Mobile Services, OAID from Huawei Mobile Services) that the SDK
  /// otherwise reports to Mindbox alongside application events.
  /// Android only, ignored on iOS.
  ///
  /// Collection is on by default; pass `true` to stop it. This is the only
  /// supported way to opt out: removing the `AD_ID` permission from the
  /// manifest affects the whole app and does not stop OAID collection.
  /// The SDK never requests a runtime permission of its own. RuStore
  /// supplies no tracking identifier.
  ///
  /// Unlike most options, it is re-read on every initialization, so it can
  /// be turned on or off in a later app version. A changed value takes effect
  /// once `init` has run in that version; native work started earlier
  /// (push services set up in `Application.onCreate`, background token
  /// refresh) still uses the previous value.
  ///
  /// When `null` (default), the key is not sent and the native default is
  /// used (`false` — the identifier is collected).
  final bool? disableTrackingIds;

  /// Returns map of parameters
  Map<String, dynamic> toMap() => {
        'domain': domain,
        'endpointIos': endpointIos,
        'endpointAndroid': endpointAndroid,
        'previousDeviceUUID': previousDeviceUUID,
        'previousInstallationId': previousInstallationId,
        'subscribeCustomerIfCreated': subscribeCustomerIfCreated,
        'shouldCreateCustomer': shouldCreateCustomer,
        'operationsDomain': operationsDomain,
        if (shouldIncludeVersionCode != null)
          'shouldIncludeVersionCode': shouldIncludeVersionCode,
        if (disableTrackingIds != null)
          'disableTrackingIds': disableTrackingIds,
      };
}

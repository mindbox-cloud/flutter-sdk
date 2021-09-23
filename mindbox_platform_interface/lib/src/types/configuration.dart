/// The class represents the information for SDK initialization.
class Configuration{
  /// Constructs a Configuration.
  Configuration({required this.domain, required this.endpoint});

  /// Used for generating baseurl for REST
  final String domain;

  /// Used for app identification
  final String endpoint;
}
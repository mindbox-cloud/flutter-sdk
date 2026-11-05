/// Why a block failed, for logs and analytics. Later SDK versions may add reasons, so keep a fallback
/// when matching.
class MindboxEmbeddedBlockFailReason {
  /// A reason by its raw value.
  const MindboxEmbeddedBlockFailReason(this.rawValue);

  /// The SDK could not get the content: no network or config, no answer within the block's
  /// `timeout`, or the page did not load.
  static const MindboxEmbeddedBlockFailReason networkError =
      MindboxEmbeddedBlockFailReason('networkError');

  /// The page did not report usable content or the SDK failed inside; also reported off iOS and
  /// Android.
  static const MindboxEmbeddedBlockFailReason internalError =
      MindboxEmbeddedBlockFailReason('internalError');

  /// The reason's name, the same on every platform.
  final String rawValue;

  @override
  bool operator ==(Object other) =>
      other is MindboxEmbeddedBlockFailReason && other.rawValue == rawValue;

  @override
  int get hashCode => rawValue.hashCode;

  @override
  String toString() => rawValue;
}

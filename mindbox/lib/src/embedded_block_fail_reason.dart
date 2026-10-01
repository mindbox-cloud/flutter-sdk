/// Why a block could not be shown — the payload of `MindboxEmbeddedBlock.onFail`.
///
/// Meant for logs and analytics on the host side, not for branching: whatever the reason, the block
/// has already collapsed or switched to its error screen. A string-backed class rather than an enum
/// so a later SDK can add a reason without breaking an exhaustive `switch` — keep a fallback when
/// matching. The raw values are the same on every platform: what the native iOS and Android blocks
/// report under these names reaches Flutter unchanged.
class MindboxEmbeddedBlockFailReason {
  /// A reason by its raw value. The constants below are the ones this version knows; a later SDK
  /// may report a word that is not among them, and it arrives through this constructor as it is.
  const MindboxEmbeddedBlockFailReason(this.rawValue);

  /// The content is unavailable because of the environment: the config could not be downloaded and
  /// nothing is cached, the SDK gave no answer within the block's waiting budget, the block's page
  /// could not be loaded, or the data the targeting needs could not be fetched — typically a
  /// network problem.
  static const MindboxEmbeddedBlockFailReason networkError =
      MindboxEmbeddedBlockFailReason('networkError');

  /// An error on the Mindbox side: the page loaded but never reported its content or reported
  /// something unusable, or the SDK failed inside. Also what a platform without a native block
  /// reports.
  static const MindboxEmbeddedBlockFailReason internalError =
      MindboxEmbeddedBlockFailReason('internalError');

  /// The stable name of the reason, the same on every platform.
  final String rawValue;

  @override
  bool operator ==(Object other) =>
      other is MindboxEmbeddedBlockFailReason && other.rawValue == rawValue;

  @override
  int get hashCode => rawValue.hashCode;

  @override
  String toString() => rawValue;
}

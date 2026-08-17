/// What the embedded block needs on both sides of the platform boundary.
///
/// The block is a view, not a call, so nothing here lands on `MindboxPlatform`: what crosses the
/// boundary is a platform view type, one channel per created view, and the two signals the native
/// block sends up — whether it occupies space and how its load ended.

/// The type both native factories register the block under.
const String embeddedBlockViewType = 'mindbox.cloud/flutter-sdk/embedded_block';

/// The channel of one created block.
///
/// Per view and not per plugin: a screen may hold several blocks, and each of them reports on its
/// own.
String embeddedBlockChannelName(int viewId) => '$embeddedBlockViewType/$viewId';

/// Keys of the creation params the native factory reads.
class EmbeddedBlockParams {
  EmbeddedBlockParams._();

  static const String placeSystemName = 'placeSystemName';
  static const String height = 'height';
}

/// Methods of the per-view channel.
class EmbeddedBlockMethods {
  EmbeddedBlockMethods._();

  /// Native → Dart: where the block stands now, as an [EmbeddedBlockReport].
  static const String report = 'report';

  /// Dart → native: whether the host still shows the block.
  static const String setHostVisible = 'setHostVisible';
}

/// How the block's load ended. There are two outcomes and no more: the block is either shown or it
/// is not — an empty place reaches the host as [EmbeddedBlockOutcome.fail], the same as a failure.
enum EmbeddedBlockOutcome { load, fail }

/// What the native block says about itself.
class EmbeddedBlockReport {
  const EmbeddedBlockReport({required this.isVisible, this.outcome});

  /// Whether the block occupies space. `false` — it collapsed, and the space is the host's again.
  ///
  /// The native container decides this: the rules for a placeholder, an opted-in error screen and
  /// an empty place all live there, and Dart only mirrors the answer in its layout.
  final bool isVisible;

  /// How the load ended, or `null` while it has not ended.
  final EmbeddedBlockOutcome? outcome;

  /// Reads a report off the channel, or `null` if the message is not one.
  ///
  /// Tolerant on purpose: a native side newer than the Dart one may send fields this version does
  /// not know, and that is no reason to break the block.
  static EmbeddedBlockReport? tryParse(Object? arguments) {
    if (arguments is! Map) {
      return null;
    }

    final Object? isVisible = arguments[_isVisibleKey];
    if (isVisible is! bool) {
      return null;
    }

    return EmbeddedBlockReport(
      isVisible: isVisible,
      outcome: _outcomeOf(arguments[_outcomeKey]),
    );
  }

  static EmbeddedBlockOutcome? _outcomeOf(Object? raw) {
    if (raw == _loadOutcome) {
      return EmbeddedBlockOutcome.load;
    }
    if (raw == _failOutcome) {
      return EmbeddedBlockOutcome.fail;
    }
    return null;
  }

  static const String _isVisibleKey = 'isVisible';
  static const String _outcomeKey = 'outcome';
  static const String _loadOutcome = 'load';
  static const String _failOutcome = 'fail';
}

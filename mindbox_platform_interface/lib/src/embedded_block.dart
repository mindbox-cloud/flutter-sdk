/// The platform view type both native factories register the embedded block under.
const String embeddedBlockViewType = 'mindbox.cloud/flutter-sdk/embedded_block';

/// The channel of the block with platform view [viewId].
String embeddedBlockChannelName(int viewId) => '$embeddedBlockViewType/$viewId';

/// The channel shared by all blocks, asked before a block exists.
const String embeddedBlockPluginChannelName = '$embeddedBlockViewType/plugin';

/// Keys of the block's creation params.
class EmbeddedBlockParams {
  EmbeddedBlockParams._();

  /// The place system name.
  static const String placeSystemName = 'placeSystemName';

  /// The block's height in logical pixels; read on iOS only.
  static const String height = 'height';

  /// The timeout in whole milliseconds; absent means the native default.
  static const String timeoutMs = 'timeoutMs';

  /// `automatic`, `placeholder` or `hidden`; absent means `automatic`.
  static const String loadingStrategy = 'loadingStrategy';

  /// Whether the SDK animates the reveal; absent means `true`.
  static const String animatesReveal = 'animatesReveal';

  /// Whether the host draws its own placeholder.
  static const String hasPlaceholder = 'hasPlaceholder';

  /// Whether the host draws its own error view; without one a failed block collapses.
  static const String hasErrorView = 'hasErrorView';
}

/// Methods of the block's channel.
class EmbeddedBlockMethods {
  EmbeddedBlockMethods._();

  /// Native → Dart: an [EmbeddedBlockReport].
  static const String report = 'report';

  /// Dart → native: send the current report again; the first one goes out before Dart listens.
  static const String sync = 'sync';

  /// Dart → native: whether the host shows the block.
  static const String setHostVisible = 'setHostVisible';

  /// Dart → native: the two [EmbeddedBlockParams] booleans for a live block.
  static const String setStandIns = 'setStandIns';

  /// Dart → native, on [embeddedBlockPluginChannelName]: the [EmbeddedBlockAppearance] word a new
  /// block of a place and strategy starts with.
  static const String initialAppearance = 'initialAppearance';

  /// Dart → native: stop the block now; sent on iOS only, where a platform view has no dispose hook.
  static const String release = 'release';
}

/// How the block occupies its place.
enum EmbeddedBlockAppearance {
  /// A placeholder at the block's height.
  placeholder,

  /// The content at the block's height.
  content,

  /// The error view at the block's height.
  error,

  /// Zero height.
  collapsed,
}

/// How the block's load ended.
enum EmbeddedBlockOutcome {
  /// The content is shown.
  load,

  /// The place has nothing to show.
  empty,

  /// The block failed; see [EmbeddedBlockReport.failReason].
  fail,
}

/// A message the native block sends on its channel.
class EmbeddedBlockReport {
  /// Creates a report.
  const EmbeddedBlockReport({
    this.appearance,
    this.outcome,
    this.failReason,
    this.isRevealAnimated = false,
    this.revealDuration,
  });

  /// The block's appearance, or `null` for a word this version does not know.
  final EmbeddedBlockAppearance? appearance;

  /// How the load ended, or `null` while it has not.
  final EmbeddedBlockOutcome? outcome;

  /// The fail reason's raw value, or `null` when the outcome is not a failure.
  final String? failReason;

  /// Whether [appearance] is the SDK's animated reveal of the content.
  final bool isRevealAnimated;

  /// The reveal's duration, sent with [isRevealAnimated].
  final Duration? revealDuration;

  /// Reads a report off the channel, or returns `null` if [arguments] is not one.
  static EmbeddedBlockReport? tryParse(Object? arguments) {
    if (arguments is! Map) {
      return null;
    }

    final Object? reason = arguments[_reasonKey];
    final Object? revealDurationMs = arguments[_revealDurationMsKey];
    return EmbeddedBlockReport(
      appearance: appearanceOf(arguments[_appearanceKey]),
      outcome: _outcomeOf(arguments[_outcomeKey]),
      failReason: reason is String ? reason : null,
      isRevealAnimated: arguments[_animatedKey] == true,
      revealDuration: revealDurationMs is int ? Duration(milliseconds: revealDurationMs) : null,
    );
  }

  /// The appearance for [word], or `null` for a word this version does not know.
  static EmbeddedBlockAppearance? appearanceOf(Object? word) => _appearances[word];

  static EmbeddedBlockOutcome? _outcomeOf(Object? raw) => _outcomes[raw];

  static const Map<Object?, EmbeddedBlockAppearance> _appearances =
      <Object?, EmbeddedBlockAppearance>{
    'placeholder': EmbeddedBlockAppearance.placeholder,
    'content': EmbeddedBlockAppearance.content,
    'error': EmbeddedBlockAppearance.error,
    'collapsed': EmbeddedBlockAppearance.collapsed,
  };

  static const Map<Object?, EmbeddedBlockOutcome> _outcomes = <Object?, EmbeddedBlockOutcome>{
    'load': EmbeddedBlockOutcome.load,
    'empty': EmbeddedBlockOutcome.empty,
    'fail': EmbeddedBlockOutcome.fail,
  };

  static const String _appearanceKey = 'appearance';
  static const String _outcomeKey = 'outcome';
  static const String _reasonKey = 'reason';
  static const String _animatedKey = 'animated';
  static const String _revealDurationMsKey = 'revealDurationMs';
}

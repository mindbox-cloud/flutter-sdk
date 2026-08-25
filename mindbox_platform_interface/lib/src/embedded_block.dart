/// What the embedded block needs on both sides of the platform boundary.
///
/// The block is a view, not a call, so nothing here lands on `MindboxPlatform`: what crosses the
/// boundary is a platform view type, one channel per created view, and the two signals the native
/// block sends up — how it occupies its place and how its load ended.

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

  /// The name of the place from the admin panel — what the native block resolves its content by.
  static const String placeSystemName = 'placeSystemName';

  /// The height the block occupies, in logical pixels. Read only by the iOS factory: on Android the
  /// block is sized by the platform view it is placed in.
  static const String height = 'height';

  /// How long the block may wait to learn what it shows, in whole milliseconds. Absent means the
  /// host said nothing and the native default stands.
  ///
  /// Milliseconds and not a [Duration]: what crosses the boundary is what the standard codec
  /// carries, and each native side spells the budget its own way — seconds on iOS, milliseconds on
  /// Android. The integer is the one spelling both can read.
  static const String timeoutMs = 'timeoutMs';

  /// Whether the host draws a loading screen of its own.
  ///
  /// Not the screen itself: a Flutter widget cannot be handed to a native container, and a widget
  /// that could would leave its tree and lose the theme, the locale and the inherited objects it was
  /// written against. The container is told only that the place is taken, and answers by holding
  /// back its own shimmer.
  static const String hasPlaceholder = 'hasPlaceholder';

  /// Whether the host draws a failure of its own — the same arrangement as [hasPlaceholder], with
  /// one difference: this is also what opts the block into showing a failure at all. Without it a
  /// failed block collapses.
  static const String hasErrorView = 'hasErrorView';
}

/// Methods of the per-view channel.
class EmbeddedBlockMethods {
  EmbeddedBlockMethods._();

  /// Native → Dart: where the block stands now, as an [EmbeddedBlockReport].
  static const String report = 'report';

  /// Dart → native: report where the block stands, whatever it is.
  ///
  /// Asked once, as soon as the channel has a handler. The native block hands out its appearance the
  /// moment the wrapper subscribes — which happens while the platform view is being built, before
  /// Dart can listen — and a place with nothing behind it settles synchronously right there. Without
  /// this the first report of such a block goes to a channel nobody is on yet, and the widget waits
  /// out its whole life on a loading screen for a block that already collapsed.
  static const String sync = 'sync';

  /// Dart → native: whether the host still shows the block.
  static const String setHostVisible = 'setHostVisible';

  /// Dart → native: whether the host draws its own placeholder and failure, as the two
  /// [EmbeddedBlockParams] booleans.
  ///
  /// The same answer as the creation params, for a block that is already live: the host may gain or
  /// lose either screen between builds.
  static const String setStandIns = 'setStandIns';
}

/// How the block occupies its place right now — what the wrapper draws, not what happened.
///
/// The rules behind the decision stay in the native container: the content states, the rule that an
/// empty place shows no failure, the one that a place taken by loading is a place drawn. Dart
/// mirrors the answer in its layout and nothing more, so every wrapper of the SDK shows the same
/// thing at the same moment by construction.
enum EmbeddedBlockAppearance {
  /// The content is loading. A host with a placeholder of its own draws it; without one the
  /// container's shimmer is already on screen.
  placeholder,

  /// The block content is shown — the host draws nothing over it.
  content,

  /// The block failed and the host opted into showing it. Never appears for an empty place.
  error,

  /// The block occupies no space: a failure without a host failure screen, or an empty place. The
  /// space goes back to the layout.
  collapsed,
}

/// How the block's load ended. There are two outcomes and no more: the block is either shown or it
/// is not — an empty place reaches the host as [EmbeddedBlockOutcome.fail], the same as a failure.
enum EmbeddedBlockOutcome {
  /// The content is shown.
  load,

  /// The place ended up without content — the load failed or timed out, or there was nothing
  /// behind the name.
  fail,
}

/// What the native block says about itself.
class EmbeddedBlockReport {
  /// Both parts are optional: a message carries whichever of them it has to say.
  const EmbeddedBlockReport({this.appearance, this.outcome});

  /// What to draw, or `null` when the message carries no answer this version understands.
  ///
  /// The appearance is a state and not an event: the same value arrives more than once, and the
  /// host keeps the last one it knew when a message brings none.
  final EmbeddedBlockAppearance? appearance;

  /// How the load ended, or `null` while it has not ended.
  ///
  /// Sent apart from [appearance] because the two are decided apart: the container settles its
  /// layers inside its own state change and delivers the outcome on the next turn of the main
  /// queue. Deriving one from the other would move the host's callback to the wrong moment.
  final EmbeddedBlockOutcome? outcome;

  /// Reads a report off the channel, or `null` if the message is not one.
  ///
  /// Tolerant on purpose: a native side newer than the Dart one may send fields — or appearances —
  /// this version does not know, and that is no reason to break the block.
  static EmbeddedBlockReport? tryParse(Object? arguments) {
    if (arguments is! Map) {
      return null;
    }

    return EmbeddedBlockReport(
      appearance: _appearanceOf(arguments[_appearanceKey]),
      outcome: _outcomeOf(arguments[_outcomeKey]),
    );
  }

  static EmbeddedBlockAppearance? _appearanceOf(Object? raw) =>
      _appearances[raw];

  static EmbeddedBlockOutcome? _outcomeOf(Object? raw) {
    if (raw == _loadOutcome) {
      return EmbeddedBlockOutcome.load;
    }
    if (raw == _failOutcome) {
      return EmbeddedBlockOutcome.fail;
    }
    return null;
  }

  static const Map<Object?, EmbeddedBlockAppearance> _appearances =
      <Object?, EmbeddedBlockAppearance>{
    'placeholder': EmbeddedBlockAppearance.placeholder,
    'content': EmbeddedBlockAppearance.content,
    'error': EmbeddedBlockAppearance.error,
    'collapsed': EmbeddedBlockAppearance.collapsed,
  };

  static const String _appearanceKey = 'appearance';
  static const String _outcomeKey = 'outcome';
  static const String _loadOutcome = 'load';
  static const String _failOutcome = 'fail';
}

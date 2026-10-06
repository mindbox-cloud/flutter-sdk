/// What the embedded block needs on both sides of the platform boundary.
///
/// The block is a view, not a call, so nothing here lands on `MindboxPlatform`: what crosses the
/// boundary is a platform view type, one channel per created view, and the two signals the native
/// block sends up — how it occupies its place and how its load ended, with the reason of a failure.

/// The type both native factories register the block under.
const String embeddedBlockViewType = 'mindbox.cloud/flutter-sdk/embedded_block';

/// The channel of one created block.
///
/// Per view and not per plugin: a screen may hold several blocks, and each of them reports on its
/// own.
String embeddedBlockChannelName(int viewId) => '$embeddedBlockViewType/$viewId';

/// The channel shared by every block, asked before any of them exists.
///
/// One question goes there: the look a block of a place starts with. A block that waits hidden must
/// not be preceded by a frame of reserved space, and for the `automatic` strategy the answer depends
/// on the SDK's memory of the place — which only the native side has.
const String embeddedBlockPluginChannelName = '$embeddedBlockViewType/plugin';

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

  /// What the block shows until the SDK answers, as the word of a loading strategy: `automatic`,
  /// `placeholder` or `hidden` — the same three words on every platform. Absent means `automatic`.
  static const String loadingStrategy = 'loadingStrategy';

  /// Whether the SDK animates the reveal of the content. Absent means it does.
  static const String animatesReveal = 'animatesReveal';

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

  /// Dart → native, on [embeddedBlockPluginChannelName]: the look a block of
  /// [EmbeddedBlockParams.placeSystemName] with [EmbeddedBlockParams.loadingStrategy] starts with,
  /// answered as the word of an [EmbeddedBlockAppearance].
  ///
  /// Asked for `automatic` only: the other two strategies are decided by the strategy alone, on
  /// either side. The native block's own report, once the platform view exists, answers the same
  /// question, so a late answer here is outranked by it.
  static const String initialAppearance = 'initialAppearance';

  /// Dart → native: the widget is gone — stop the block now, not when the last reference to it is.
  ///
  /// Sent on iOS and nowhere else. Android has a dispose hook for the platform view and iOS has
  /// none, so there the block would be released by `deinit` — whenever the engine happens to let go
  /// of the view. Dart knows the moment exactly, and a page loading for a screen that no longer
  /// exists is what the wait costs.
  ///
  /// Android is not told, and not merely because its hook already does it: the platform view is a
  /// child of the widget that owns this channel, and children are unmounted first, so by the time
  /// the widget could speak the hook has run — releasing the block and taking the channel's handler
  /// down with it. The message would reach a channel nobody is on and come back as a missing plugin.
  /// The Android side still answers it, for a host that says it by another road.
  static const String release = 'release';
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

/// How the block's load ended. Three outcomes and no more: the content is shown, the place has
/// nothing to show, or the block could not be shown. The native block tells them apart, and the host
/// hears each one through its own callback.
enum EmbeddedBlockOutcome {
  /// The content is shown.
  load,

  /// The place has nothing to show: no campaign behind the name, the targeting or the A/B group
  /// did not match, the show budget is spent, or the page rendered nothing. A normal outcome, not a
  /// breakage, and no reason comes with it.
  empty,

  /// The block could not be shown: the SDK had no config or never answered, the page could not be
  /// loaded, the content is malformed or the SDK hit an internal error. Comes with a reason, see
  /// [EmbeddedBlockReport.failReason].
  fail,
}

/// What the native block says about itself.
class EmbeddedBlockReport {
  /// Every part is optional: a message carries whichever of them it has to say.
  const EmbeddedBlockReport({
    this.appearance,
    this.outcome,
    this.failReason,
    this.isRevealAnimated = false,
    this.revealDuration,
  });

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

  /// Why the block failed, as the native side spells it — `networkError`, `internalError`, or a
  /// word a later SDK added — or `null` when the outcome is not a failure.
  ///
  /// Carried raw on purpose: the raw values are the same on every platform and the SDK may add
  /// reasons, so the boundary passes the word through and leaves the typing to the widget.
  final String? failReason;

  /// Whether the [appearance] of this report is the SDK's reveal of the content — the one change
  /// that is animated. The native block owns that decision, gates included: `animatesReveal`, the
  /// system's reduced motion, and the rule that only the arrival of content is a reveal. The
  /// container fades the content in on its own; the wrapper that lays the block out animates the
  /// growth of a block that waited hidden, and this is what tells it to.
  final bool isRevealAnimated;

  /// How long the SDK's reveal takes, sent with [isRevealAnimated]; `null` otherwise. The
  /// wrapper's growth runs for as long as the container's fade, so the two end together.
  final Duration? revealDuration;

  /// Reads a report off the channel, or `null` if the message is not one.
  ///
  /// Tolerant on purpose: a native side newer than the Dart one may send fields — or appearances —
  /// this version does not know, and that is no reason to break the block.
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

  /// The appearance behind its word on the channel, or `null` for a word this version does not know.
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

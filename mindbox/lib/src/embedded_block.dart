import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

/// An embedded Mindbox block.
///
/// The app marks a *place* by its [placeSystemName] and never learns what goes into it — that is the
/// config's decision, and it can change without an app release. **The host owns the size**: pass the
/// [height] the block should occupy. A place that ends up without content collapses to zero height
/// and hands the space back.
///
/// ```dart
/// MindboxEmbeddedBlock(
///   placeSystemName: 'main-screen-top',
///   height: 104,
/// )
/// ```
///
/// Both outcomes can be customized, the same way as in SwiftUI and Compose: [placeholder] replaces
/// the stock loading shimmer, and [errorBuilder] opts into showing a failure instead of collapsing.
/// Both stay ordinary widgets, built in place and mounted inside the block, so they resolve the
/// theme, the locale and the inherited objects of the tree the block itself stands in — and a
/// callback of the host works from them like from any other widget.
///
/// ```dart
/// MindboxEmbeddedBlock(
///   placeSystemName: 'stories',
///   height: 104,
///   placeholder: (_) => const StoriesSkeleton(),
///   errorBuilder: (_) => const StoriesUnavailable(),
/// )
/// ```
///
/// How long the block may wait before it gives its place back is the [timeout], and a host that
/// leaves it out gets the SDK's own budget of 30 seconds.
///
/// The widget is a thin layer over the native block: the platform view holds the SDK's own container
/// — with its waiting budget and its web page — and this widget only mirrors the container's
/// decisions in the Flutter layout, and draws the host's own screens over it when it asks for them.
///
/// **iOS and Android.** On any other platform the block collapses right away and reports [onFail], so
/// a layout that hides its section on failure behaves the same everywhere.
class MindboxEmbeddedBlock extends StatelessWidget {
  /// Creates a block for the place named [placeSystemName], occupying [height].
  const MindboxEmbeddedBlock({
    Key? key,
    required this.placeSystemName,
    required this.height,
    this.timeout,
    this.placeholder,
    this.errorBuilder,
    this.onLoad,
    this.onFail,
  }) : super(key: key);

  /// The name of the place from the admin panel. A different name is a different block, built from
  /// scratch in place of the old one.
  final String placeSystemName;

  /// The height the block occupies while it loads and while it is shown. Fixed when the block is
  /// created: a new value given to a live block is ignored and reported to the log.
  ///
  /// To resize a block that is already on screen, give the widget a new [Key] — that is a new block,
  /// built from scratch, and it reloads its content.
  final double height;

  /// How long the block waits to learn what it shows before it gives its place back. `null` — the
  /// default — is the SDK's own budget of 30 seconds.
  ///
  /// The budget covers the wait for the answer, not the whole life of the block: a page that has
  /// already arrived gets its own time to render, and that is not shortened by a small timeout here.
  /// An answer that comes in later no longer expands a block that has given up; the next attempt
  /// starts when the block comes back on screen.
  ///
  /// The wait is the user's, not the clock's: it is counted only while the screen the block stands
  /// on is the one being looked at, and a block left behind a pushed route keeps the remainder of
  /// its budget for when the user comes back.
  ///
  /// Zero or negative is not a budget — such a block would collapse before the SDK could answer at
  /// all — so the native side keeps its default instead and writes down what it was given.
  ///
  /// Fixed when the block is created, exactly as [height] is: a new value given to a live block is
  /// ignored and reported to the log. Give the widget a new [Key] to load a block on a new budget.
  final Duration? timeout;

  /// Built instead of the SDK shimmer while the block is loading.
  ///
  /// Fills the whole place, as the native placeholder does: the widget is given the block's full
  /// width and height as tight constraints. A screen that should be smaller says so itself, with an
  /// [Align] or a [Center]; one that could be taller has to fit — anything over [height] overflows.
  final WidgetBuilder? placeholder;

  /// Built instead of collapsing when the block cannot be shown.
  ///
  /// Applies only to failures: an empty place — one with nothing behind its place system name —
  /// always collapses, so a host cannot fill the space of a block that was never meant to be there.
  ///
  /// Adding it to a block that has *already* collapsed does not bring the space back: reopening
  /// space the layout has reclaimed would make it jump. Such a builder takes effect on a load that
  /// starts the cycle anew, never on the silent retry a return to the screen brings. Passing it
  /// from the start is what a host that wants a failure screen should do.
  final WidgetBuilder? errorBuilder;

  /// The content is shown.
  final VoidCallback? onLoad;

  /// The place ended up without content: the load failed or timed out, or there is nothing behind
  /// the name. An empty place is a normal outcome, not a breakage.
  final VoidCallback? onFail;

  @override
  Widget build(BuildContext context) {
    return _EmbeddedBlock(
      // A different place is a different block, and everything remembered about the old one has to
      // go with it — the outcome already delivered, the appearance last shown, the height fixed at
      // creation. Keying the state and not just the platform view is what `.id(placeSystemName)`
      // does in SwiftUI; keying only the view would keep a live State pointing at a dead block.
      key: ValueKey<String>(placeSystemName),
      placeSystemName: placeSystemName,
      height: height,
      timeout: timeout,
      placeholder: placeholder,
      errorBuilder: errorBuilder,
      onLoad: onLoad,
      onFail: onFail,
    );
  }
}

class _EmbeddedBlock extends StatefulWidget {
  const _EmbeddedBlock({
    Key? key,
    required this.placeSystemName,
    required this.height,
    required this.timeout,
    required this.placeholder,
    required this.errorBuilder,
    required this.onLoad,
    required this.onFail,
  }) : super(key: key);

  final String placeSystemName;
  final double height;
  final Duration? timeout;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;
  final VoidCallback? onLoad;
  final VoidCallback? onFail;

  @override
  State<_EmbeddedBlock> createState() => _EmbeddedBlockState();
}

class _EmbeddedBlockState extends State<_EmbeddedBlock> {
  /// The height as given, kept to tell an ignored new value from the one the block was built with.
  late final double _creationHeight = widget.height;

  /// The height as laid out. Clamped like the native container and the SwiftUI wrapper do — a
  /// negative height computed from a `MediaQuery` reaches the block as a broken constraint here,
  /// while on the native side it is only a log line and an invisible block.
  late final double _height = math.max(0, _creationHeight);

  /// The budget as given, kept for the same reason the height is: it goes to the native block once,
  /// when the platform view is created, and a later value has no container left to reach.
  ///
  /// Taken in `initState` rather than on first read: on a platform without a native block nothing
  /// reads it while the block is being built, and a lazy field would be filled in by the very
  /// comparison meant to catch a changed budget — with the changed value.
  late final Duration? _creationTimeout;

  /// Starts where the native container starts: the space is taken and the loading screen is up. The
  /// block occupies its height right away, not from the container's first report.
  EmbeddedBlockAppearance _appearance = EmbeddedBlockAppearance.placeholder;

  EmbeddedBlockOutcome? _deliveredOutcome;

  bool _hasWarnedAboutHeight = false;

  bool _hasWarnedAboutTimeout = false;

  MethodChannel? _channel;

  /// What the native side was last *told*, not what the widget last held.
  ///
  /// The difference is the whole point: a change that happens before the platform view exists has
  /// nowhere to go, and comparing against the previous widget would call that change delivered and
  /// never mention it again. Compared against this, an undelivered change stays pending until the
  /// channel appears.
  bool? _syncedHasPlaceholder;
  bool? _syncedHasErrorView;
  bool? _syncedHostVisible;

  bool _isHostVisible = true;

  bool get _hasPlaceholder => widget.placeholder != null;

  bool get _hasErrorView => widget.errorBuilder != null;

  /// The platforms that have a native block behind the widget. Both wrap the very same container,
  /// speak the same channel and answer with the same appearances — that is the whole point of the
  /// arrangement, and it is why the widget itself needs no per-platform branch beyond which platform
  /// view class to build.
  ///
  /// The web is excluded by name: there [defaultTargetPlatform] mirrors the browser's host OS, so
  /// without [kIsWeb] a phone's browser would claim a native block no browser can build — instead
  /// of collapsing the way every other platform without one does.
  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _creationTimeout = widget.timeout;
    if (!_isSupported) {
      // No platform view means no reports and no outcome — and a host told to drop its section in
      // `onFail` would keep an empty hole forever waiting for one. Answer the way an empty place
      // answers, so the layout around the block behaves the same on every platform.
      // `WidgetsBinding.instance` reads as non-nullable only from Flutter 3, and this package still
      // declares a 2.0 floor. `ensureInitialized` returns the binding itself on both — inside a
      // widget it is long up, so nothing is initialized here: this is the same instance, spelled in
      // a way that compiles either side of the change.
      WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _appearance = EmbeddedBlockAppearance.collapsed);
        _deliver(EmbeddedBlockOutcome.fail);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `Overlay` turns tickers off for a route covered by an opaque one, which is exactly when a
    // Flutter screen stops being seen while its platform view stays in the window.
    // `valuesOf` is the non-deprecated spelling, but it is newer than the Flutter floor this
    // package declares, and `of` says everything the block needs.
    // ignore: deprecated_member_use
    _isHostVisible = TickerMode.of(context);
    _pushHostVisible();
  }

  @override
  void didUpdateWidget(covariant _EmbeddedBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _warnIfCreationValuesAreIgnored();
    _pushStandIns();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? hostLayer = _hostLayer(context);

    return SizedBox(
      height: _appearance == EmbeddedBlockAppearance.collapsed ? 0 : _height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _nativeBlock(),
          // Nothing to draw is no child at all. An empty widget would be harmless to touches — it
          // hit-tests to nothing and the block underneath still hears them — but it is a layer the
          // engine has to composite over the platform view for no reason at all.
          if (hostLayer != null) hostLayer,
        ],
      ),
    );
  }

  /// The host's own screen for the current appearance, or `null` when the host draws nothing.
  Widget? _hostLayer(BuildContext context) {
    switch (_appearance) {
      case EmbeddedBlockAppearance.placeholder:
        return widget.placeholder?.call(context);
      case EmbeddedBlockAppearance.error:
        return widget.errorBuilder?.call(context);
      case EmbeddedBlockAppearance.content:
      case EmbeddedBlockAppearance.collapsed:
        return null;
    }
  }

  Widget _nativeBlock() {
    if (!_isSupported) {
      return const SizedBox.shrink();
    }

    final Map<String, Object> creationParams = <String, Object>{
      EmbeddedBlockParams.placeSystemName: widget.placeSystemName,
      EmbeddedBlockParams.height: _height,
      // The container is told that the place is taken, not what goes into it: it holds back its
      // shimmer and keeps a failed block standing, and Dart draws the screen itself.
      EmbeddedBlockParams.hasPlaceholder: _hasPlaceholder,
      EmbeddedBlockParams.hasErrorView: _hasErrorView,
    };

    // Sent only when the host named one: an absent key is what tells either native side to keep its
    // own default, and there is no number that means "no budget" to put there instead.
    final Duration? timeout = _creationTimeout;
    if (timeout != null) {
      creationParams[EmbeddedBlockParams.timeoutMs] = timeout.inMilliseconds;
    }

    // A block is typically a horizontal carousel inside a vertical scroll. Flutter has no parent to
    // ask not to intercept touches — the gesture arena decides — so the platform view has to claim
    // horizontal drags itself, or the surrounding list takes them first.
    //
    // Only while the content is what is on screen. Under a host's own screen the block has nothing
    // to scroll, and claiming drags there would take them from a placeholder or a failure screen
    // that scrolls or swipes on its own.
    final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        _appearance == EmbeddedBlockAppearance.content
            ? <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
                ),
              }
            : const <Factory<OneSequenceGestureRecognizer>>{};

    // The only place in the widget that knows which platform it is on. Everything else — the layers,
    // the height, the outcome, the two signals sent down — is written once and reads the same answer
    // from either native side.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: embeddedBlockViewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: gestureRecognizers,
        onPlatformViewCreated: _listenTo,
      );
    }

    return UiKitView(
      viewType: embeddedBlockViewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: gestureRecognizers,
      onPlatformViewCreated: _listenTo,
    );
  }

  void _listenTo(int viewId) {
    // A platform view can be built again for the same `State` — a new id, a new native container
    // that has heard nothing. What was sent to the previous one is not what this one knows, and
    // left in place it would silence the resend below: a block whose host is already hidden would
    // match the answer it sent the old view, say nothing, and let the new one — which starts out
    // believing it is on screen — spend its whole waiting budget behind a covered route.
    _channel?.setMethodCallHandler(null);
    _syncedHasPlaceholder = null;
    _syncedHasErrorView = null;
    _syncedHostVisible = null;

    final MethodChannel channel = MethodChannel(embeddedBlockChannelName(viewId));
    channel.setMethodCallHandler(_handle);
    _channel = channel;
    // Where does the block stand? Asked rather than assumed: the container hands out its appearance
    // the moment the native wrapper subscribes, which is while the platform view is being built —
    // before this handler existed. A place with nothing behind it settles right there, and its only
    // report would be lost, leaving the widget on a loading screen for a block that already gave its
    // space back.
    _invoke(channel, EmbeddedBlockMethods.sync, null);
    // Everything the block was told before it existed is told now. The platform view is created a
    // few frames after the first build, and a host that gains a failure screen — or leaves the
    // screen — inside that window would otherwise be heard by nobody, permanently.
    _pushStandIns();
    _pushHostVisible();
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != EmbeddedBlockMethods.report) {
      return;
    }

    final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(call.arguments);
    if (report == null || !mounted) {
      return;
    }

    final EmbeddedBlockAppearance? appearance = report.appearance;
    if (appearance != null && appearance != _appearance) {
      setState(() => _appearance = appearance);
    }

    _deliver(report.outcome);
  }

  /// The native side reports where the block stands, not what changed, so the same outcome can
  /// arrive more than once — the host must hear it exactly once.
  void _deliver(EmbeddedBlockOutcome? outcome) {
    if (outcome == null || outcome == _deliveredOutcome) {
      return;
    }

    _deliveredOutcome = outcome;
    if (outcome == EmbeddedBlockOutcome.load) {
      widget.onLoad?.call();
    } else {
      widget.onFail?.call();
    }
  }

  /// Whether the host draws its own screens can change between builds — a placeholder given only
  /// while a feature flag is on, a failure screen added once the section knows it can retry.
  ///
  /// Only the answer travels, not the builder: a widget rebuilt with a different closure that still
  /// draws a placeholder is the same answer, and telling the container about it on every frame would
  /// make it swap its layers for nothing.
  void _pushStandIns() {
    final MethodChannel? channel = _channel;
    if (channel == null ||
        (_syncedHasPlaceholder == _hasPlaceholder && _syncedHasErrorView == _hasErrorView)) {
      return;
    }

    _syncedHasPlaceholder = _hasPlaceholder;
    _syncedHasErrorView = _hasErrorView;
    _invoke(
      channel,
      EmbeddedBlockMethods.setStandIns,
      <String, Object>{
        EmbeddedBlockParams.hasPlaceholder: _hasPlaceholder,
        EmbeddedBlockParams.hasErrorView: _hasErrorView,
      },
    );
  }

  /// Tells the block whether the screen it stands on is still the one being looked at.
  ///
  /// The native container watches its window, and in Flutter that is not enough: every screen shares
  /// one window, so pushing a route over the block never takes it out. Left alone, the block would
  /// spend its whole waiting budget behind another screen and collapse before the user came back to
  /// a place that never gets its space again.
  void _pushHostVisible() {
    final MethodChannel? channel = _channel;
    if (channel == null || _syncedHostVisible == _isHostVisible) {
      return;
    }

    _syncedHostVisible = _isHostVisible;
    _invoke(channel, EmbeddedBlockMethods.setHostVisible, _isHostVisible);
  }

  /// Sends and forgets, but does not leave the failure unhandled: a call into a platform view the
  /// engine has already disposed answers with a `MissingPluginException`, and an uncaught one
  /// surfaces to the host as a crash report for a block that is simply gone.
  void _invoke(MethodChannel channel, String method, Object? arguments) {
    channel.invokeMethod<void>(method, arguments).catchError((Object error) {
      debugPrint('[MindboxEmbeddedBlock] $method for block "${widget.placeSystemName}" '
          'was not delivered: $error');
    });
  }

  /// Both the height and the budget are settled when the block is built and cannot be talked out of
  /// it afterwards. Said once per value, and separately: a host that changed only one of them should
  /// hear about that one.
  void _warnIfCreationValuesAreIgnored() {
    if (!_hasWarnedAboutHeight && widget.height != _creationHeight) {
      _hasWarnedAboutHeight = true;
      debugPrint(
        '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was given height ${widget.height} '
        'after creation and keeps $_creationHeight: the height is fixed when the block is created. '
        'Give the widget a new Key to build a block of a different height.',
      );
    }

    if (!_hasWarnedAboutTimeout && widget.timeout != _creationTimeout) {
      _hasWarnedAboutTimeout = true;
      debugPrint(
        '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was given timeout '
        '${widget.timeout} after creation and keeps $_creationTimeout: the timeout is fixed when '
        'the block is created. Give the widget a new Key to load a block on a different budget.',
      );
    }
  }
}

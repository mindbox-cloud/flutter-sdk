import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
    this.keepAlive = true,
    this.placeholder,
    this.errorBuilder,
    this.onLoad,
    this.onFail,
  }) : super(key: key);

  /// The name of the place from the admin panel. A different name is a different block, built from
  /// scratch in place of the old one.
  ///
  /// Taken exactly as given: nothing is trimmed, so spaces around the name are part of it and keep
  /// the block from matching the place. The widget writes such a name to the log.
  final String placeSystemName;

  /// The height the block occupies while it loads and while it is shown. Live: a new value given
  /// to a live block resizes it in place — the same content, no reload — exactly as the SwiftUI
  /// and Compose wrappers behave.
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
  /// Fixed when the block is created: a new value given to a live block is ignored and reported
  /// to the log. Give the widget a new [Key] to load a block on a new budget.
  final Duration? timeout;

  /// Whether the block survives being scrolled out of a lazy list.
  ///
  /// A `ListView`, a `GridView` or any other lazy sliver builds only what is near the viewport and
  /// throws the rest away — a block scrolled far enough would be disposed with its row, and on the
  /// way back a *new* block would load its content from scratch: a full cycle with the shimmer on
  /// every pass across the screen. The native iOS and Android blocks do not behave that way: a view
  /// in a scroll is paused off screen, not destroyed, and its page is shown again as it was.
  ///
  /// `true` — the default — asks the list to keep the block alive, so it matches the native blocks:
  /// off screen its content is paused, and on the way back the same page is shown at once, with no
  /// reload, no shimmer and no second [onLoad]. Outside a lazy list the flag changes nothing.
  ///
  /// The pause is the widget's doing, not only the platform's: a kept block that the list has
  /// scrolled out of view is reported to the native block as hidden, the same way a block behind a
  /// pushed route is. On iOS the platform view also leaves the window, on Android it stays attached
  /// and would otherwise count as visible — running its page, spending its waiting budget and
  /// accounting a show nobody sees.
  ///
  /// The price is memory: every kept block holds its web page for as long as the list lives. A
  /// screen with many blocks that is better off paying a reload than holding them all can turn this
  /// off, and then the block is disposed with its row exactly as any other widget is. Live: a new
  /// value takes effect on the block in place.
  final bool keepAlive;

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
  ///
  /// Delivered once per outcome, not once per lifetime: the same outcome is never repeated, and an
  /// outcome that actually changed — a place that filled up after a failure — is delivered again.
  /// The native block reports the same way, so every wrapper of the SDK calls back alike.
  final VoidCallback? onLoad;

  /// The place ended up without content: the load failed or timed out, or there is nothing behind
  /// the name. An empty place is a normal outcome, not a breakage.
  ///
  /// Delivered on the same rule as [onLoad]: once per outcome, again if the outcome changes.
  final VoidCallback? onFail;

  @override
  Widget build(BuildContext context) {
    return _EmbeddedBlock(
      key: ValueKey<String>(placeSystemName),
      placeSystemName: placeSystemName,
      height: height,
      timeout: timeout,
      keepAlive: keepAlive,
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
    required this.keepAlive,
    required this.placeholder,
    required this.errorBuilder,
    required this.onLoad,
    required this.onFail,
  }) : super(key: key);

  final String placeSystemName;
  final double height;
  final Duration? timeout;
  final bool keepAlive;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;
  final VoidCallback? onLoad;
  final VoidCallback? onFail;

  @override
  State<_EmbeddedBlock> createState() => _EmbeddedBlockState();
}

/// Kept alive in a lazy list by default: the platform view — and the SDK container with its page
/// behind it — is what a reload costs, and a row of a `ListView` is rebuilt on every pass across the
/// screen. Off screen the native block pauses itself (it leaves the window), so keeping it costs
/// memory, not work; see [MindboxEmbeddedBlock.keepAlive].
class _EmbeddedBlockState extends State<_EmbeddedBlock> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive;

  double get _height => widget.height.isFinite ? math.max(0, widget.height) : 0;

  late final Duration? _creationTimeout;

  EmbeddedBlockAppearance _appearance = EmbeddedBlockAppearance.placeholder;

  EmbeddedBlockOutcome? _deliveredOutcome;

  bool _hasWarnedAboutTimeout = false;

  MethodChannel? _channel;

  bool? _syncedHasPlaceholder;
  bool? _syncedHasErrorView;
  bool? _syncedHostVisible;

  bool _isTickerEnabled = true;

  /// The list keeps the block alive, and it is out of view. Read from the sliver's parent data
  /// after every frame while [MindboxEmbeddedBlock.keepAlive] is on.
  bool _isKeptAliveOffscreen = false;

  bool _isKeptAliveCheckArmed = false;

  bool get _isHostVisible => _isTickerEnabled && !_isKeptAliveOffscreen;

  bool get _hasPlaceholder => widget.placeholder != null;

  bool get _hasErrorView => widget.errorBuilder != null;

  static bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _creationTimeout = widget.timeout;
    _warnIfPlaceIsPadded();
    _warnIfHeightReservesNoSpace();
    _armKeptAliveCheck();
    if (!_isSupported) {
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
    // ignore: deprecated_member_use
    _isTickerEnabled = TickerMode.of(context);
    _pushHostVisible();
  }

  @override
  void didUpdateWidget(covariant _EmbeddedBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
      if (widget.keepAlive) {
        _armKeptAliveCheck();
      } else {
        // A block that is not kept is disposed when it leaves the list, so off screen it is
        // never in a state to hide.
        _isKeptAliveOffscreen = false;
        _pushHostVisible();
      }
    }
    _warnIfTimeoutIsIgnored();
    _pushStandIns();
  }

  @override
  void dispose() {
    final MethodChannel? channel = _channel;
    if (channel != null) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        _invoke(channel, EmbeddedBlockMethods.release, null);
      }
      channel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The mixin's build is what hands the list the keep-alive handle; its widget is not used.
    super.build(context);
    final Widget? hostLayer = _hostLayer(context);

    return SizedBox(
      height: _appearance == EmbeddedBlockAppearance.collapsed ? 0 : _height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _nativeBlock(),
          if (hostLayer != null) hostLayer,
        ],
      ),
    );
  }

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
      EmbeddedBlockParams.hasPlaceholder: _hasPlaceholder,
      EmbeddedBlockParams.hasErrorView: _hasErrorView,
    };

    final Duration? timeout = _creationTimeout;
    if (timeout != null) {
      creationParams[EmbeddedBlockParams.timeoutMs] = timeout.inMilliseconds;
    }

    // The recognizer is built by hand rather than by a RawGestureDetector, so nothing hands it the
    // touch slop of the device the way the framework hands it to every scrollable. Left to itself it
    // falls back to kTouchSlop — 18 logical pixels against the 8 an Android scrollable plays with —
    // and a scrollable that wants the same direction takes the drag while the block is still short
    // of its own threshold: the arena closes, and the carousel is never told a finger was on it. On
    // equal slop the drag goes to whoever is closest to the finger, and inside the block that is the
    // block.
    //
    // Read whole rather than by aspect: the aspect accessors arrived in Flutter 3.10, and the plugin
    // still speaks to 3.0. Watching all of MediaQuery costs nothing here — a platform view keeps the
    // recognizer it was first given, so the settings are read once however they are asked for.
    final DeviceGestureSettings? gestureSettings = MediaQuery.maybeOf(context)?.gestureSettings;

    final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        _appearance == EmbeddedBlockAppearance.content
            ? <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer()..gestureSettings = gestureSettings,
                ),
              }
            : const <Factory<OneSequenceGestureRecognizer>>{};

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
    _channel?.setMethodCallHandler(null);
    _syncedHasPlaceholder = null;
    _syncedHasErrorView = null;
    _syncedHostVisible = null;

    final MethodChannel channel = MethodChannel(embeddedBlockChannelName(viewId));
    channel.setMethodCallHandler(_handle);
    _channel = channel;
    _invoke(channel, EmbeddedBlockMethods.sync, null);
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

  void _pushHostVisible() {
    final MethodChannel? channel = _channel;
    if (channel == null || _syncedHostVisible == _isHostVisible) {
      return;
    }

    _syncedHostVisible = _isHostVisible;
    _invoke(channel, EmbeddedBlockMethods.setHostVisible, _isHostVisible);
  }

  /// Whether the list has parked the block off screen. A lazy sliver flips `keptAlive` on the
  /// child's parent data while it lays out, so the answer is read once the frame is done.
  ///
  /// The walk stops at the first ancestor that is a sliver's child; a block outside any lazy list
  /// never finds one and is never off screen by this measure.
  bool _readKeptAliveOffscreen() {
    RenderObject? node = context.findRenderObject();
    while (node != null) {
      final ParentData? parentData = node.parentData;
      if (parentData is KeepAliveParentDataMixin) {
        return parentData.keptAlive;
      }

      // `parent` is typed as the abstract node on the oldest Flutter the plugin speaks to, and as
      // a render object on the newest — the check reads on both without a cast to warn about.
      final Object? parent = node.parent;
      node = parent is RenderObject ? parent : null;
    }
    return false;
  }

  /// Re-armed after every frame while the block is kept alive. A post-frame callback runs only
  /// when a frame is produced, so a list that stands still costs nothing; a list that scrolls
  /// pays a short walk up the render tree per block per frame.
  void _armKeptAliveCheck() {
    if (_isKeptAliveCheckArmed || !widget.keepAlive || !_isSupported) {
      return;
    }

    _isKeptAliveCheckArmed = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _isKeptAliveCheckArmed = false;
      if (!mounted) {
        return;
      }

      final bool keptAliveOffscreen = _readKeptAliveOffscreen();
      if (keptAliveOffscreen != _isKeptAliveOffscreen) {
        _isKeptAliveOffscreen = keptAliveOffscreen;
        _pushHostVisible();
      }
      _armKeptAliveCheck();
    });
  }

  void _invoke(MethodChannel channel, String method, Object? arguments) {
    channel.invokeMethod<void>(method, arguments).catchError((Object error) {
      debugPrint('[MindboxEmbeddedBlock] $method for block "${widget.placeSystemName}" '
          'was not delivered: $error');
    });
  }

  void _warnIfPlaceIsPadded() {
    final String placeSystemName = widget.placeSystemName;
    if (placeSystemName.trim() == placeSystemName) {
      return;
    }

    debugPrint(
      '[MindboxEmbeddedBlock] Block "$placeSystemName" was given a place system name with spaces '
      'around it. The name is used as it is, so it will not match the place from the admin panel.',
    );
  }

  void _warnIfHeightReservesNoSpace() {
    if (widget.height.isFinite && widget.height > 0) {
      return;
    }

    debugPrint(
      '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was created with height '
      '${widget.height}: it reserves no space and nothing loads.',
    );
  }

  void _warnIfTimeoutIsIgnored() {
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

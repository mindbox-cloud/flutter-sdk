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
  late final double _creationHeight = widget.height;

  late final double _height = math.max(0, _creationHeight);

  late final Duration? _creationTimeout;

  EmbeddedBlockAppearance _appearance = EmbeddedBlockAppearance.placeholder;

  EmbeddedBlockOutcome? _deliveredOutcome;

  bool _hasWarnedAboutHeight = false;

  bool _hasWarnedAboutTimeout = false;

  MethodChannel? _channel;

  bool? _syncedHasPlaceholder;
  bool? _syncedHasErrorView;
  bool? _syncedHostVisible;

  bool _isHostVisible = true;

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

    final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers =
        _appearance == EmbeddedBlockAppearance.content
            ? <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
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

  void _invoke(MethodChannel channel, String method, Object? arguments) {
    channel.invokeMethod<void>(method, arguments).catchError((Object error) {
      debugPrint('[MindboxEmbeddedBlock] $method for block "${widget.placeSystemName}" '
          'was not delivered: $error');
    });
  }

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

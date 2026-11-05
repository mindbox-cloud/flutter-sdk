import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

import 'embedded_block_fail_reason.dart';
import 'embedded_block_loading_strategy.dart';

/// Shows the Mindbox embedded block configured for a place in the admin panel.
///
/// Give it a height and let the layout set its position and width. Keep it in the layout rather than
/// removing it in [onEmpty]: a collapsed block still shows content the place gets later.
/// [timeout], [loadingStrategy] and [animatesReveal] are read only when the block is created; give
/// the widget a new [Key] to change them. On platforms other than iOS and Android the block
/// collapses and reports [onFail] with [MindboxEmbeddedBlockFailReason.internalError].
///
/// ```dart
/// MindboxEmbeddedBlock(
///   placeSystemName: 'stories',
///   height: 104,
///   placeholder: (_) => const StoriesSkeleton(),
///   onFail: (reason) => log('stories failed: $reason'),
/// )
/// ```
class MindboxEmbeddedBlock extends StatelessWidget {
  /// Creates a block for the place named [placeSystemName].
  const MindboxEmbeddedBlock({
    Key? key,
    required this.placeSystemName,
    required this.height,
    this.timeout,
    this.loadingStrategy = MindboxEmbeddedBlockLoadingStrategy.automatic,
    this.animatesReveal = true,
    this.keepAlive = true,
    this.placeholder,
    this.errorBuilder,
    this.onLoad,
    this.onEmpty,
    this.onFail,
  }) : super(key: key);

  /// The place's system name from the admin panel, matched ignoring letter case and surrounding
  /// whitespace. A new name builds a new block.
  final String placeSystemName;

  /// The block's height while it is not collapsed; a new value resizes the block in place. A block
  /// created without a positive height loads nothing until it gets one.
  final double height;

  /// How long the block waits for the SDK to choose its content before it fails with
  /// [MindboxEmbeddedBlockFailReason.networkError], counted while its screen is shown. `null`, zero
  /// or negative means 30 seconds.
  final Duration? timeout;

  /// What the block shows while it loads; [MindboxEmbeddedBlockLoadingStrategy.automatic] by default.
  final MindboxEmbeddedBlockLoadingStrategy loadingStrategy;

  /// Whether the SDK animates the content's appearance; `true` by default. Set `false` to animate the
  /// block's container yourself in [onLoad].
  final bool animatesReveal;

  /// Whether a lazy list keeps the block alive off screen, so it comes back without a reload; `true`
  /// by default, and can change at any time. A kept block holds its page and its row in memory: set
  /// `false` on a screen with many blocks.
  final bool keepAlive;

  /// Shown instead of the SDK's shimmer while the block loads, at the block's full size.
  final WidgetBuilder? placeholder;

  /// Shown, instead of collapsing, when the block fails while it takes its height. Pass it from the
  /// start: adding it later does not expand a collapsed block.
  final WidgetBuilder? errorBuilder;

  /// Called when the content is shown.
  final VoidCallback? onLoad;

  /// Called when the block collapses because the place has nothing to show or the data its targeting
  /// needs could not be fetched.
  final VoidCallback? onEmpty;

  /// Called when the block fails; it collapses or shows [errorBuilder].
  final void Function(MindboxEmbeddedBlockFailReason reason)? onFail;

  @override
  Widget build(BuildContext context) {
    return _EmbeddedBlock(
      key: ValueKey<String>(placeSystemName),
      placeSystemName: placeSystemName,
      height: height,
      timeout: timeout,
      loadingStrategy: loadingStrategy,
      animatesReveal: animatesReveal,
      keepAlive: keepAlive,
      placeholder: placeholder,
      errorBuilder: errorBuilder,
      onLoad: onLoad,
      onEmpty: onEmpty,
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
    required this.loadingStrategy,
    required this.animatesReveal,
    required this.keepAlive,
    required this.placeholder,
    required this.errorBuilder,
    required this.onLoad,
    required this.onEmpty,
    required this.onFail,
  }) : super(key: key);

  final String placeSystemName;
  final double height;
  final Duration? timeout;
  final MindboxEmbeddedBlockLoadingStrategy loadingStrategy;
  final bool animatesReveal;
  final bool keepAlive;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorBuilder;
  final VoidCallback? onLoad;
  final VoidCallback? onEmpty;
  final void Function(MindboxEmbeddedBlockFailReason reason)? onFail;

  @override
  State<_EmbeddedBlock> createState() => _EmbeddedBlockState();
}

class _EmbeddedBlockState extends State<_EmbeddedBlock>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive && _isSupported;

  double get _height => widget.height.isFinite ? math.max(0, widget.height) : 0;

  late final Duration? _creationTimeout;
  late final MindboxEmbeddedBlockLoadingStrategy _creationLoadingStrategy;
  late final bool _creationAnimatesReveal;

  late EmbeddedBlockAppearance _appearance;

  bool _hasHeardFromNative = false;

  late final AnimationController _reveal;

  EmbeddedBlockAppearance? _fadingAppearance;

  late final AnimationController _fade;
  late final Animation<double> _fadeOut;

  late final Curve _revealCurve;

  EmbeddedBlockOutcome? _deliveredOutcome;

  bool _hasHadSpace = false;

  final Set<String> _warnedCreationValues = <String>{};

  MethodChannel? _channel;

  bool? _syncedHasPlaceholder;
  bool? _syncedHasErrorView;
  bool? _syncedHostVisible;

  bool _isTickerEnabled = true;

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
    _creationLoadingStrategy = widget.loadingStrategy;
    _creationAnimatesReveal = widget.animatesReveal;
    _appearance = _firstLook(_creationLoadingStrategy);
    _reveal = AnimationController(vsync: this, value: 1);
    _revealCurve = defaultTargetPlatform == TargetPlatform.android
        ? Curves.fastOutSlowIn
        : Curves.easeInOut;
    _fade = AnimationController(vsync: this, value: 1)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed && _fadingAppearance != null && mounted) {
          setState(() => _fadingAppearance = null);
        }
      });
    _fadeOut = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _fade, curve: _revealCurve));
    _warnIfHeightReservesNoSpace();
    _armKeptAliveCheck();
    _askForTheFirstLook();
    if (!_isSupported) {
      WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _appearance = EmbeddedBlockAppearance.collapsed);
        _deliver(EmbeddedBlockOutcome.fail, MindboxEmbeddedBlockFailReason.internalError);
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
    }
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
    _reveal.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Widget? hostLayer = _hostLayer(context);

    // Android never creates a zero-size platform view, so the block keeps its height in the slot.
    final Widget block = ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: _height,
        maxHeight: _height,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _nativeBlock(),
            if (hostLayer != null) hostLayer,
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _reveal,
      child: block,
      builder: (BuildContext context, Widget? child) => SizedBox(
        height: _slotHeight,
        child: child,
      ),
    );
  }

  double get _slotHeight {
    if (_appearance == EmbeddedBlockAppearance.collapsed) {
      return 0;
    }
    return _height * _revealCurve.transform(_reveal.value);
  }

  static EmbeddedBlockAppearance _firstLook(MindboxEmbeddedBlockLoadingStrategy strategy) {
    switch (strategy) {
      case MindboxEmbeddedBlockLoadingStrategy.placeholder:
        return EmbeddedBlockAppearance.placeholder;
      case MindboxEmbeddedBlockLoadingStrategy.hidden:
      case MindboxEmbeddedBlockLoadingStrategy.automatic:
        return EmbeddedBlockAppearance.collapsed;
    }
  }

  void _askForTheFirstLook() {
    if (!_isSupported ||
        _creationLoadingStrategy != MindboxEmbeddedBlockLoadingStrategy.automatic) {
      return;
    }

    _pluginChannel.invokeMethod<String>(EmbeddedBlockMethods.initialAppearance, <String, Object>{
      EmbeddedBlockParams.placeSystemName: widget.placeSystemName,
      EmbeddedBlockParams.loadingStrategy: _strategyWords[_creationLoadingStrategy]!,
    }).then((String? word) {
      final EmbeddedBlockAppearance? appearance = EmbeddedBlockReport.appearanceOf(word);
      if (!mounted || _hasHeardFromNative || appearance == null || appearance == _appearance) {
        return;
      }
      _show(appearance);
    }).catchError((Object error) {
      debugPrint('[MindboxEmbeddedBlock] initialAppearance for block "${widget.placeSystemName}" '
          'was not answered: $error');
    });
  }

  void _show(EmbeddedBlockAppearance appearance, {Duration? revealDuration}) {
    final EmbeddedBlockAppearance previous = _appearance;
    final bool animated = revealDuration != null && revealDuration > Duration.zero;
    final bool arrives = appearance == EmbeddedBlockAppearance.content;
    final bool opens = arrives && previous == EmbeddedBlockAppearance.collapsed;
    final bool replacesHostLayer = arrives && animated && _hostLayerBuilder(previous) != null;

    setState(() {
      _appearance = appearance;
      _fadingAppearance = replacesHostLayer ? previous : null;
    });

    if (opens && animated) {
      _reveal.duration = revealDuration;
      _reveal.forward(from: 0);
    } else {
      _reveal.value = 1;
    }

    if (replacesHostLayer) {
      _fade.duration = revealDuration;
      _fade.forward(from: 0);
    } else {
      _fade.value = 1;
    }
  }

  static const MethodChannel _pluginChannel = MethodChannel(embeddedBlockPluginChannelName);

  static const Map<MindboxEmbeddedBlockLoadingStrategy, String> _strategyWords =
      <MindboxEmbeddedBlockLoadingStrategy, String>{
    MindboxEmbeddedBlockLoadingStrategy.automatic: 'automatic',
    MindboxEmbeddedBlockLoadingStrategy.placeholder: 'placeholder',
    MindboxEmbeddedBlockLoadingStrategy.hidden: 'hidden',
  };

  Widget? _hostLayer(BuildContext context) {
    final EmbeddedBlockAppearance? fading = _fadingAppearance;
    if (fading != null) {
      final Widget? layer = _hostLayerBuilder(fading)?.call(context);
      if (layer != null) {
        return IgnorePointer(child: FadeTransition(opacity: _fadeOut, child: layer));
      }
    }
    return _hostLayerBuilder(_appearance)?.call(context);
  }

  WidgetBuilder? _hostLayerBuilder(EmbeddedBlockAppearance appearance) {
    switch (appearance) {
      case EmbeddedBlockAppearance.placeholder:
        return widget.placeholder;
      case EmbeddedBlockAppearance.error:
        return widget.errorBuilder;
      case EmbeddedBlockAppearance.content:
      case EmbeddedBlockAppearance.collapsed:
        return null;
    }
  }

  Widget _nativeBlock() {
    _hasHadSpace = _hasHadSpace || _height > 0;
    if (!_isSupported || !_hasHadSpace) {
      return const SizedBox.shrink();
    }

    final Map<String, Object> creationParams = <String, Object>{
      EmbeddedBlockParams.placeSystemName: widget.placeSystemName,
      EmbeddedBlockParams.height: _height,
      EmbeddedBlockParams.loadingStrategy: _strategyWords[_creationLoadingStrategy]!,
      EmbeddedBlockParams.animatesReveal: _creationAnimatesReveal,
      EmbeddedBlockParams.hasPlaceholder: _hasPlaceholder,
      EmbeddedBlockParams.hasErrorView: _hasErrorView,
    };

    final Duration? timeout = _creationTimeout;
    if (timeout != null) {
      creationParams[EmbeddedBlockParams.timeoutMs] = timeout.inMilliseconds;
    }

    // Without the device's touch slop the recognizer uses kTouchSlop and loses drags to scrollables.
    // MediaQuery is read whole: its aspect accessors arrived in Flutter 3.10.
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

    _hasHeardFromNative = true;
    final EmbeddedBlockAppearance? appearance = report.appearance;
    if (appearance != null && appearance != _appearance) {
      _show(appearance, revealDuration: report.isRevealAnimated ? report.revealDuration : null);
    }

    _deliver(report.outcome, _reasonOf(report.failReason));
  }

  void _deliver(EmbeddedBlockOutcome? outcome, MindboxEmbeddedBlockFailReason? reason) {
    if (outcome == null || outcome == _deliveredOutcome) {
      return;
    }

    _deliveredOutcome = outcome;
    switch (outcome) {
      case EmbeddedBlockOutcome.load:
        widget.onLoad?.call();
        break;
      case EmbeddedBlockOutcome.empty:
        widget.onEmpty?.call();
        break;
      case EmbeddedBlockOutcome.fail:
        widget.onFail?.call(reason ?? MindboxEmbeddedBlockFailReason.internalError);
        break;
    }
  }

  static MindboxEmbeddedBlockFailReason? _reasonOf(String? rawValue) =>
      rawValue == null ? null : MindboxEmbeddedBlockFailReason(rawValue);

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

  // Walks to the root: a keep-alive request reaches every enclosing lazy list.
  bool _readKeptAliveOffscreen() {
    RenderObject? node = context.findRenderObject();
    while (node != null) {
      final ParentData? parentData = node.parentData;
      if (parentData is KeepAliveParentDataMixin && parentData.keptAlive) {
        return true;
      }

      // `parent` is an AbstractNode on older Flutter and a RenderObject on newer.
      final Object? parent = node.parent;
      node = parent is RenderObject ? parent : null;
    }
    return false;
  }

  void _armKeptAliveCheck() {
    if (_isKeptAliveCheckArmed || !_isSupported) {
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

  void _warnIfHeightReservesNoSpace() {
    if (widget.height.isFinite && widget.height > 0) {
      return;
    }

    debugPrint(
      '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was created with height '
      '${widget.height}: it reserves no space and nothing loads until it is given a height.',
    );
  }

  void _warnIfCreationValuesAreIgnored() {
    _warnIfCreationValueIsIgnored('timeout', widget.timeout, _creationTimeout);
    _warnIfCreationValueIsIgnored(
        'loadingStrategy', widget.loadingStrategy, _creationLoadingStrategy);
    _warnIfCreationValueIsIgnored('animatesReveal', widget.animatesReveal, _creationAnimatesReveal);
  }

  void _warnIfCreationValueIsIgnored(String name, Object? given, Object? kept) {
    if (given == kept || !_warnedCreationValues.add('$name=$given')) {
      return;
    }

    debugPrint(
      '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was given $name $given after '
      'creation and keeps $kept: $name is fixed when the block is created. Give the widget a new '
      'Key to build a block anew.',
    );
  }
}

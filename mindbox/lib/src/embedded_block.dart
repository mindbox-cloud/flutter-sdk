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
/// Both looks can be customized, the same way as in SwiftUI and Compose: [placeholder] replaces
/// the stock loading shimmer, and [errorBuilder] opts into showing a failure instead of collapsing.
/// Both stay ordinary widgets, built in place and mounted inside the block, so they resolve the
/// theme, the locale and the inherited objects of the tree the block itself stands in — and a
/// callback of the host works from them like from any other widget. Neither is built before the
/// block has taken its place: a block that waits hidden — `hidden`, or `automatic` at a place with
/// no record yet, which is what a fresh install gets by default — shows no placeholder while it
/// waits, and a failure during that wait collapses it without the error screen.
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
/// What the block shows until the SDK has decided what goes into it is the [loadingStrategy]: a
/// placeholder, nothing, or — by default — nothing until the place has shown content once on this
/// device and a placeholder from then on. The content is revealed with the SDK's own animation — it
/// fades in, and a block that started hidden grows to its height — unless [animatesReveal] is off.
///
/// The widget is a thin layer over the native block: the platform view holds the SDK's own container
/// — with its waiting budget and its web page — and this widget only mirrors the container's
/// decisions in the Flutter layout, and draws the host's own screens over it when it asks for them.
///
/// The outcome arrives through three callbacks, the same three as in SwiftUI and Compose: [onLoad]
/// when the content is shown, [onEmpty] when there is nothing to show at the place, and [onFail] with
/// a reason when the block could not be shown.
///
/// **iOS and Android.** On any other platform the block collapses right away and reports [onFail]
/// with [MindboxEmbeddedBlockFailReason.internalError], so a layout that hides its section on
/// failure behaves the same everywhere.
class MindboxEmbeddedBlock extends StatelessWidget {
  /// Creates a block for the place named [placeSystemName], occupying [height].
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

  /// The name of the place from the admin panel. A different name is a different block, built from
  /// scratch in place of the old one.
  ///
  /// Passed down as given. Whitespace around the name is not part of it: the native blocks ignore
  /// it, so a name pasted from the admin panel with a stray space still finds its place. The name
  /// itself is matched the way the native SDK matches it.
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

  /// What the block shows until the SDK answers — see [MindboxEmbeddedBlockLoadingStrategy].
  ///
  /// [MindboxEmbeddedBlockLoadingStrategy.automatic] — the default — keeps the block hidden until
  /// the place has shown content once on this device and puts a placeholder there from then on. A
  /// block that takes its space up front keeps the layout still at the price of flashing where
  /// there is nothing to show; a block that waits hidden never flashes at the price of the layout
  /// growing when content arrives. A place that always has a campaign behind it is worth an
  /// explicit [MindboxEmbeddedBlockLoadingStrategy.placeholder].
  ///
  /// A block that waits hidden — `hidden`, or `automatic` at a place with no record — builds
  /// neither [placeholder] nor [errorBuilder] before its first content: a failure during that
  /// wait collapses it, and only [onFail] tells.
  ///
  /// Fixed when the block is created, as [timeout] is: a new value given to a live block is
  /// ignored and reported to the log. Give the widget a new [Key] to build a block anew.
  final MindboxEmbeddedBlockLoadingStrategy loadingStrategy;

  /// Whether the SDK animates the reveal of the content — a fade, and the growth of a block that
  /// waited hidden. `true` by default; the system's reduced-motion setting turns the animation off
  /// as well. Turn it off to animate the block's container yourself in [onLoad].
  ///
  /// Fixed when the block is created, as [timeout] is.
  final bool animatesReveal;

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
  /// The price is memory: every kept block holds its web page for as long as the list lives, and
  /// the request keeps the whole row alive — the row's own widgets with it — in every lazy list
  /// the block stands in, a carousel inside a feed included. A screen with many blocks that is
  /// better off paying a reload than holding them all can turn this off, and then the block is
  /// disposed with its row exactly as any other widget is. Live: a new value takes effect on the
  /// block in place.
  final bool keepAlive;

  /// Built instead of the SDK shimmer while the block is loading.
  ///
  /// Fills the whole place, as the native placeholder does: the widget is given the block's full
  /// width and height as tight constraints. A screen that should be smaller says so itself, with an
  /// [Align] or a [Center]; one that could be taller has to fit — anything over [height] overflows.
  ///
  /// Not built while the block waits hidden — `hidden`, or `automatic` at a place that has not
  /// shown content yet: such a block takes no space, so there is nothing to fill. Once content was
  /// shown, the placeholder keeps the space while the page is replaced. When the content arrives
  /// with the SDK's reveal, the placeholder fades out under it for as long as the content fades in.
  final WidgetBuilder? placeholder;

  /// Built instead of collapsing when the block cannot be shown.
  ///
  /// Applies only to failures: an empty place — one with nothing behind its place system name —
  /// always collapses, so a host cannot fill the space of a block that was never meant to be there.
  ///
  /// Nor does it apply to a block that waits hidden — `hidden`, or `automatic` at a place that has
  /// not shown content yet, which is what the default gives a fresh install: a block that never
  /// took its space does not take it for an error screen, so a failure collapses it and only
  /// [onFail] tells. A host that wants the error screen on the very first load names
  /// [MindboxEmbeddedBlockLoadingStrategy.placeholder].
  ///
  /// Adding it to a block that has *already* collapsed does not bring the space back: reopening
  /// space the layout has reclaimed would make it jump. Such a builder takes effect on a load that
  /// starts the cycle anew, never on the silent retry a return to the screen brings. Passing it
  /// from the start is what a host that wants a failure screen should do.
  final WidgetBuilder? errorBuilder;

  /// The content is shown: the block has taken its height and is visible.
  ///
  /// A block that waited hidden only starts to grow here: the slot goes from 0 to [height] over
  /// the SDK's reveal, so a host that measures the block or scrolls to it on this call sees it
  /// still near zero.
  ///
  /// Delivered once per outcome, not once per lifetime: the same outcome is never repeated, and an
  /// outcome that actually changed — a place that filled up after a failure — is delivered again.
  /// The native block reports the same way, so every wrapper of the SDK calls back alike.
  final VoidCallback? onLoad;

  /// There is nothing to show at the place: no campaign behind its name, the targeting or the A/B
  /// group did not match, the show budget is spent, or the page rendered nothing. A normal outcome,
  /// not a breakage: the block collapses, [errorBuilder] does not apply, and no reason is given —
  /// which of these it was is the SDK's business.
  ///
  /// Delivered on the same rule as [onLoad]: once per outcome, again if the outcome changes.
  final VoidCallback? onEmpty;

  /// The block could not be shown: the SDK had no config or never answered, the page could not be
  /// loaded, the content is malformed or the SDK hit an internal error. The block collapses, or
  /// keeps its height and builds [errorBuilder] when one is given — unless it waited hidden: a
  /// block that never took its space collapses on a failure whatever [errorBuilder] says. An empty
  /// place is not a failure and arrives in [onEmpty] instead.
  ///
  /// The reason is for logs and analytics, not for branching: whatever it is, the block has already
  /// collapsed or switched to [errorBuilder]. Compare it with the constants of
  /// [MindboxEmbeddedBlockFailReason] and keep a fallback — a later SDK may add reasons.
  ///
  /// Delivered on the same rule as [onLoad]: once per outcome, again if the outcome changes. A
  /// failure that repeats with a different reason is the same outcome and is not delivered again.
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

/// Kept alive in a lazy list by default: the platform view — and the SDK container with its page
/// behind it — is what a reload costs, and a row of a `ListView` is rebuilt on every pass across the
/// screen. Off screen the block is paused rather than destroyed — by the window on iOS, and by the
/// hidden signal this widget sends on Android — so keeping it costs memory, not work; see
/// [MindboxEmbeddedBlock.keepAlive]. A platform without a native block has nothing worth keeping.
class _EmbeddedBlockState extends State<_EmbeddedBlock>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => widget.keepAlive && _isSupported;

  double get _height => widget.height.isFinite ? math.max(0, widget.height) : 0;

  late final Duration? _creationTimeout;
  late final MindboxEmbeddedBlockLoadingStrategy _creationLoadingStrategy;
  late final bool _creationAnimatesReveal;

  late EmbeddedBlockAppearance _appearance;

  /// The native block has reported on its own channel at least once. From then on the first look
  /// asked of the plugin channel is stale, whenever it arrives.
  bool _hasHeardFromNative = false;

  /// The growth of a block that waited hidden: 0 to 1 over the SDK's reveal, 1 at rest.
  late final AnimationController _reveal;

  /// The host's own placeholder or error screen on its way out: the look it stood for, kept in the
  /// tree for as long as the SDK fades the content in under it; `null` when nothing is fading.
  EmbeddedBlockAppearance? _fadingAppearance;

  /// The fade of a host layer the content replaces: 0 to 1 over the SDK's reveal, 1 at rest.
  late final AnimationController _fade;
  late final Animation<double> _fadeOut;

  /// The curve the native reveal runs on, so the slot and the layer move with the content: the
  /// standard Material curve on Android, UIKit's ease-in-out on iOS.
  late final Curve _revealCurve;

  EmbeddedBlockOutcome? _deliveredOutcome;

  /// The block has been given a height at least once. A block created with none builds no native
  /// block, as the log says; a live block passing through none keeps the one it has — `height` is
  /// live and promises no reload.
  bool _hasHadSpace = false;

  final Set<String> _warnedCreationValues = <String>{};

  MethodChannel? _channel;

  bool? _syncedHasPlaceholder;
  bool? _syncedHasErrorView;
  bool? _syncedHostVisible;

  bool _isTickerEnabled = true;

  /// A list keeps the block's row alive, and it is out of view. Read from the slivers' parent
  /// data after every frame for as long as the block is mounted.
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
    // The mixin's build is what hands the list the keep-alive handle; its widget is not used.
    super.build(context);
    final Widget? hostLayer = _hostLayer(context);

    // The slot is what the layout sees; the block inside keeps its full height whatever the slot
    // is. A platform view sized to nothing is never created on Android — the engine skips the
    // create for an empty size — so a block that waits hidden would never load and never grow.
    // With its own height under a clipped slot of zero it runs its whole cycle unseen, as the
    // native blocks do, and the slot opens when the content arrives.
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

  /// The height the layout is given: nothing for a collapsed block, the block's height otherwise —
  /// and, while a block that waited hidden is revealed, the part of it the growth has reached.
  double get _slotHeight {
    if (_appearance == EmbeddedBlockAppearance.collapsed) {
      return 0;
    }
    return _height * _revealCurve.transform(_reveal.value);
  }

  /// The look a block starts with, before the native block exists to say.
  ///
  /// `placeholder` and `hidden` are decided by the strategy alone. `automatic` is decided by the
  /// SDK's memory of the place, which only the native side has and Dart reaches asynchronously —
  /// see [_askForTheFirstLook] — so until it answers an `automatic` block takes no space: a place
  /// that has never shown content must not flash reserved space, and one that has shows its
  /// placeholder a frame late rather than a frame early.
  static EmbeddedBlockAppearance _firstLook(MindboxEmbeddedBlockLoadingStrategy strategy) {
    switch (strategy) {
      case MindboxEmbeddedBlockLoadingStrategy.placeholder:
        return EmbeddedBlockAppearance.placeholder;
      case MindboxEmbeddedBlockLoadingStrategy.hidden:
      case MindboxEmbeddedBlockLoadingStrategy.automatic:
        return EmbeddedBlockAppearance.collapsed;
    }
  }

  /// Asks the plugin — not the block, which does not exist yet — what an `automatic` block of this
  /// place starts with. The native block's own report, once the platform view is built, settles the
  /// same question and wins: an answer that comes after it is dropped.
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

  /// Takes the block to [appearance]. The arrival of content is the one change that is animated,
  /// and only when the native block says so — it owns that decision, gates included — for as long
  /// as it says: a slot that was closed grows, and a placeholder or error screen of the host's own
  /// fades out under the content the native block fades in, untouchable while it goes. Everything
  /// else lands at once, and a look arriving mid-animation takes the slot and the layer where the
  /// new look puts them.
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

  /// The words the strategies go by on the channel — the same three on every platform.
  static const Map<MindboxEmbeddedBlockLoadingStrategy, String> _strategyWords =
      <MindboxEmbeddedBlockLoadingStrategy, String>{
    MindboxEmbeddedBlockLoadingStrategy.automatic: 'automatic',
    MindboxEmbeddedBlockLoadingStrategy.placeholder: 'placeholder',
    MindboxEmbeddedBlockLoadingStrategy.hidden: 'hidden',
  };

  /// The host's own screen over the native block, if the look has one: the placeholder or the
  /// error screen — or, while the content fades in under it, the one it is replacing, on its way
  /// out and not taking touches.
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
    // A height that reserves no space builds no native block on either platform, as the log
    // says: iOS would create the view at any size and run the whole cycle unseen, and a block
    // nobody can see has no business loading a page or reporting an outcome. Only until the block
    // has had a height once: taking the native block out of the tree on a live height of zero
    // would build it anew on the way back, page and all.
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

    _hasHeardFromNative = true;
    final EmbeddedBlockAppearance? appearance = report.appearance;
    if (appearance != null && appearance != _appearance) {
      _show(appearance, revealDuration: report.isRevealAnimated ? report.revealDuration : null);
    }

    _deliver(report.outcome, _reasonOf(report.failReason));
  }

  /// Deduplicated by the kind of outcome, not by the whole report: a silent retry that fails for
  /// a different reason is still the same outcome, as it is for the native blocks.
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
        // A failure always comes with a reason; a report without one is a native side this version
        // does not expect, and the SDK's own error is the closest word for it.
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

  /// Whether a list has parked the block off screen. A lazy sliver flips `keptAlive` on the
  /// child's parent data while it lays out, so the answer is read once the frame is done.
  ///
  /// The walk goes all the way up and answers for *every* enclosing lazy list, not the nearest
  /// one: the keep-alive request travels past the first list to all the others, so a carousel
  /// inside a feed is parked by the feed while the carousel's own parent data still says the
  /// block is in place. A block outside any lazy list finds nothing and is never off screen by
  /// this measure.
  bool _readKeptAliveOffscreen() {
    RenderObject? node = context.findRenderObject();
    while (node != null) {
      final ParentData? parentData = node.parentData;
      if (parentData is KeepAliveParentDataMixin && parentData.keptAlive) {
        return true;
      }

      // `parent` is typed as the abstract node on the oldest Flutter the plugin speaks to, and as
      // a render object on the newest — the check reads on both without a cast to warn about.
      final Object? parent = node.parent;
      node = parent is RenderObject ? parent : null;
    }
    return false;
  }

  /// Re-armed after every frame for as long as the block is mounted, whatever its own
  /// [MindboxEmbeddedBlock.keepAlive] says: the block's request is not the only thing that can
  /// park its row — any keep-alive client in the row does, another block among them — and a
  /// block parked by someone else has to be hidden and shown all the same. Tying the check to
  /// the block's own flag would also leave a block that turned the flag off while parked hidden
  /// for good once its row came back.
  ///
  /// A post-frame callback runs only when a frame is produced, so a list that stands still costs
  /// nothing; a list that scrolls pays a short walk up the render tree per block per frame.
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

  /// Said once per value given, as the Compose wrapper says it: the first rebuild that brings a
  /// new value is the one worth a line in the log, not every rebuild that repeats it.
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

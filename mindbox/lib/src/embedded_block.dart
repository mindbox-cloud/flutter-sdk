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
/// The widget is a thin layer over the native block: the platform view holds the SDK's own container
/// — with its placeholder, its waiting budget and its web page — and this widget only mirrors the
/// container's decisions in the Flutter layout.
class MindboxEmbeddedBlock extends StatefulWidget {
  const MindboxEmbeddedBlock({
    Key? key,
    required this.placeSystemName,
    required this.height,
    this.onLoad,
    this.onFail,
  }) : super(key: key);

  /// The name of the place from the admin panel. A different name is a different block, built from
  /// scratch in place of the old one.
  final String placeSystemName;

  /// The height the block occupies while it loads and while it is shown. Fixed when the block is
  /// created: a new value given to a live block is ignored and reported to the log.
  final double height;

  /// The content is shown.
  final VoidCallback? onLoad;

  /// The place ended up without content: the load failed or timed out, or there is nothing behind
  /// the name. An empty place is a normal outcome, not a breakage.
  final VoidCallback? onFail;

  @override
  State<MindboxEmbeddedBlock> createState() => _MindboxEmbeddedBlockState();
}

class _MindboxEmbeddedBlockState extends State<MindboxEmbeddedBlock> {
  /// Fixed at creation, like in the SwiftUI and Compose wrappers: the native block is built with a
  /// height, and re-creating it on every new value would reload the web page — which is what a
  /// `GeometryReader` or a height animation would otherwise do on every frame.
  late final double _height = widget.height;

  /// Starts where the native container starts: the space is taken and the placeholder is up. The
  /// block occupies its height right away, not from the container's first report.
  bool _isVisible = true;

  EmbeddedBlockOutcome? _deliveredOutcome;

  bool _hasWarnedAboutHeight = false;

  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant MindboxEmbeddedBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _warnIfHeightIsIgnored();
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _isVisible ? _height : 0,
      child: _nativeBlock(),
    );
  }

  Widget _nativeBlock() {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      // Only iOS registers the platform view so far. The place still holds its height, so a layout
      // built around the block does not jump when the other platform catches up.
      return const SizedBox.shrink();
    }

    return KeyedSubtree(
      // A different place is a different block: the platform view is recreated rather than
      // repointed, the same way `key(placeSystemName)` works in Compose and `.id(…)` in SwiftUI.
      key: ValueKey<String>(widget.placeSystemName),
      child: UiKitView(
        viewType: embeddedBlockViewType,
        creationParams: <String, Object>{
          EmbeddedBlockParams.placeSystemName: widget.placeSystemName,
          EmbeddedBlockParams.height: _height,
        },
        creationParamsCodec: const StandardMessageCodec(),
        // A block is typically a horizontal carousel inside a vertical scroll. Flutter has no
        // parent to ask not to intercept touches — the gesture arena decides — so the platform view
        // has to claim horizontal drags itself, or the surrounding list takes them first.
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => HorizontalDragGestureRecognizer(),
          ),
        },
        onPlatformViewCreated: _listenTo,
      ),
    );
  }

  void _listenTo(int viewId) {
    final MethodChannel channel = MethodChannel(embeddedBlockChannelName(viewId));
    channel.setMethodCallHandler(_handle);
    _channel = channel;
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != EmbeddedBlockMethods.report) {
      return;
    }

    final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(call.arguments);
    if (report == null || !mounted) {
      return;
    }

    if (report.isVisible != _isVisible) {
      setState(() => _isVisible = report.isVisible);
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

  void _warnIfHeightIsIgnored() {
    if (_hasWarnedAboutHeight || widget.height == _height) {
      return;
    }

    _hasWarnedAboutHeight = true;
    debugPrint(
      '[MindboxEmbeddedBlock] Block "${widget.placeSystemName}" was given height ${widget.height} '
      'after creation and keeps $_height: the height is fixed when the block is created.',
    );
  }
}

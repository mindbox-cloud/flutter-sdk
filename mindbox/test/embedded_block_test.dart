import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';
import 'package:mindbox_platform_interface/mindbox_platform_interface.dart';

void testWithoutNativeBlock(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  group('On a platform without a native block', () {
    testWithoutNativeBlock('The block collapses and reports a failure',
        (WidgetTester tester) async {
      int fails = 0;
      int loads = 0;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            onLoad: () => loads++,
            onFail: () => fails++,
          ),
        ),
      ));

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 104);

      await tester.pump();

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
      expect(fails, 1);
      expect(loads, 0);
    });

    testWithoutNativeBlock('The failure is reported once, not on every rebuild',
        (WidgetTester tester) async {
      int fails = 0;

      Future<void> build() => tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: MindboxEmbeddedBlock(
                placeSystemName: 'stories',
                height: 104,
                onFail: () => fails++,
              ),
            ),
          ));

      await build();
      await tester.pump();
      await build();
      await tester.pump();

      expect(fails, 1);
    });

    testWithoutNativeBlock('A host placeholder fills the place while the block is loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            placeholder: (_) => const SizedBox.expand(key: Key('host-placeholder')),
          ),
        ),
      ));

      expect(find.byKey(const Key('host-placeholder')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('host-placeholder'))).height, 104);
    });

    testWithoutNativeBlock('An empty place shows no error screen, even when the host has one',
        (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            errorBuilder: (_) => const SizedBox.expand(key: Key('host-error')),
          ),
        ),
      ));
      await tester.pump();

      expect(find.byKey(const Key('host-error')), findsNothing);
      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
    });

    testWithoutNativeBlock('A different place is a different block', (WidgetTester tester) async {
      int fails = 0;

      Future<void> buildFor(String place) => tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: MindboxEmbeddedBlock(
                placeSystemName: place,
                height: 104,
                onFail: () => fails++,
              ),
            ),
          ));

      await buildFor('stories');
      await tester.pump();
      expect(fails, 1);

      await buildFor('promo');
      await tester.pump();
      expect(fails, 2);
    });

    testWithoutNativeBlock('A budget changed after creation is ignored, and said out loud',
        (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        Future<void> buildWith(Duration timeout) => tester.pumpWidget(Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: MindboxEmbeddedBlock(
                  placeSystemName: 'stories',
                  height: 104,
                  timeout: timeout,
                ),
              ),
            ));

        await buildWith(const Duration(seconds: 5));
        expect(log, isEmpty);

        await buildWith(const Duration(seconds: 9));
        await buildWith(const Duration(seconds: 12));
      } finally {
        debugPrint = printed;
      }

      expect(log.where((String line) => line.contains('timeout')), hasLength(1));
      expect(log.single, contains('"stories"'));
      expect(log.single, contains('0:00:05'));
    });
  });

  group('The waiting budget', () {
    late List<Map<Object?, Object?>> created;

    setUp(() {
      created = <Map<Object?, Object?>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        if (call.method != 'create') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
        final Uint8List params = arguments['params'] as Uint8List;
        created.add(const StandardMessageCodec().decodeMessage(
          params.buffer.asByteData(params.offsetInBytes, params.lengthInBytes),
        ) as Map<Object?, Object?>);
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    Future<Map<Object?, Object?>> paramsOf(
      WidgetTester tester,
      TargetPlatform platform, {
      Duration? timeout,
    }) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: 'stories',
              height: 104,
              timeout: timeout,
            ),
          ),
        ));
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(created, hasLength(1));
      return created.single;
    }

    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.iOS,
      TargetPlatform.android,
    ]) {
      final String name = platform == TargetPlatform.iOS ? 'iOS' : 'Android';

      testWidgets('Reaches the $name block as whole milliseconds',
          (WidgetTester tester) async {
        final Map<Object?, Object?> params = await paramsOf(
          tester,
          platform,
          timeout: const Duration(milliseconds: 4500),
        );

        expect(params['placeSystemName'], 'stories');
        expect(params['timeoutMs'], 4500);
      });

      testWidgets('Is left out on $name when the host names none, so the SDK default stands',
          (WidgetTester tester) async {
        final Map<Object?, Object?> params = await paramsOf(tester, platform);

        expect(params.containsKey('timeoutMs'), isFalse);
      });
    }

    testWidgets('Goes down as it was given, for the native side to judge',
        (WidgetTester tester) async {
      final Map<Object?, Object?> params = await paramsOf(
        tester,
        TargetPlatform.iOS,
        timeout: Duration.zero,
      );

      expect(params['timeoutMs'], 0);
    });
  });

  group('A height that reserves no space', () {
    Future<void> buildWith(WidgetTester tester, String placeSystemName, double height) =>
        tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: placeSystemName,
              height: height,
            ),
          ),
        ));

    testWithoutNativeBlock('A block created with no height says so in the log',
        (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        await buildWith(tester, 'stories', 0);
        await buildWith(tester, 'promo', -8);
      } finally {
        debugPrint = printed;
      }

      final Iterable<String> lines =
          log.where((String line) => line.contains('reserves no space'));
      expect(lines, hasLength(2));
      expect(lines.first, contains('"stories"'));
      expect(lines.last, contains('"promo"'));
    });

    testWithoutNativeBlock('A block with a height says nothing', (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        await buildWith(tester, 'stories', 104);
      } finally {
        debugPrint = printed;
      }

      expect(log, isEmpty);
    });
  });

  group('A place name with spaces around it', () {
    Future<void> buildWith(WidgetTester tester, String placeSystemName) =>
        tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: placeSystemName,
              height: 104,
            ),
          ),
        ));

    testWithoutNativeBlock('A padded place name says so in the log', (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        await buildWith(tester, ' stories');
        await buildWith(tester, 'promo ');
      } finally {
        debugPrint = printed;
      }

      expect(log.where((String line) => line.contains('with spaces around it')), hasLength(2));
    });

    testWithoutNativeBlock('A place name without them says nothing', (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        await buildWith(tester, 'stories');
      } finally {
        debugPrint = printed;
      }

      expect(log, isEmpty);
    });
  });

  group('The block height', () {
    late List<Map<Object?, Object?>> created;

    setUp(() {
      created = <Map<Object?, Object?>>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;

        // The engine answers a resize with the size it actually gave the platform view, and the
        // controller reads it back — a bare null there fails inside the framework, not in the SDK.
        if (call.method == 'resize') {
          return <Object?, Object?>{
            'width': arguments['width'],
            'height': arguments['height'],
          };
        }

        if (call.method != 'create') {
          return null;
        }

        final Uint8List params = arguments['params'] as Uint8List;
        created.add(const StandardMessageCodec().decodeMessage(
          params.buffer.asByteData(params.offsetInBytes, params.lengthInBytes),
        ) as Map<Object?, Object?>);
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    Future<void> buildWith(WidgetTester tester, double height) => tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: 'stories',
              height: height,
            ),
          ),
        ));

    testWidgets('A new height resizes the live block without rebuilding it',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');
      try {
        await buildWith(tester, 104);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 104);

        await buildWith(tester, 200);
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 200);
        expect(created, hasLength(1));
        expect(log, isEmpty);
      } finally {
        debugPrint = printed;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('Leaving the screen', () {
    late List<String> methods;

    setUp(() {
      methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        if (call.method != 'create') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
        final int viewId = arguments['id']! as int;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(embeddedBlockChannelName(viewId)),
          (MethodCall call) async {
            methods.add(call.method);
            return null;
          },
        );
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    Future<void> showAndDrop(WidgetTester tester, TargetPlatform platform) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await tester.pumpWidget(const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: 'stories',
              height: 104,
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(methods, contains(EmbeddedBlockMethods.sync));
        expect(methods, isNot(contains(EmbeddedBlockMethods.release)));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }

    testWidgets('A disposed widget tells the iOS block to stop', (WidgetTester tester) async {
      await showAndDrop(tester, TargetPlatform.iOS);

      expect(methods.last, EmbeddedBlockMethods.release);
    });

    testWidgets('A disposed widget leaves the Android block to its own dispose hook',
        (WidgetTester tester) async {
      await showAndDrop(tester, TargetPlatform.android);

      expect(methods, isNot(contains(EmbeddedBlockMethods.release)));
    });
  });

  group('A drag that two scrollables want', () {
    // The device slop an Android scrollable plays with. The block used to fall back to kTouchSlop —
    // 18 — and lose every horizontal drag to a parent that crosses 8 first.
    const DeviceGestureSettings settings = DeviceGestureSettings(touchSlop: 8);

    late int viewId;

    setUp(() {
      viewId = -1;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        // 'touch' carries a list, not a map: the block wins the arena and forwards the drag, so
        // this handler is asked about more than the two methods it answers.
        if (call.method != 'create' && call.method != 'resize') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;

        if (call.method == 'resize') {
          return <Object?, Object?>{
            'width': arguments['width'],
            'height': arguments['height'],
          };
        }

        viewId = arguments['id']! as int;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(embeddedBlockChannelName(viewId)),
          (MethodCall call) async => null,
        );
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    /// The native block saying it has content on screen — the only state in which the block asks
    /// for horizontal drags at all.
    Future<void> showContent(WidgetTester tester) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        embeddedBlockChannelName(viewId),
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall(
            EmbeddedBlockMethods.report,
            <String, Object>{'appearance': 'content'},
          ),
        ),
        (ByteData? _) {},
      );
      await tester.pumpAndSettle();
    }

    Future<PageController> showBlockInPageView(WidgetTester tester) async {
      final PageController pages = PageController();
      addTearDown(pages.dispose);

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(gestureSettings: settings),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PageView(
            controller: pages,
            children: const <Widget>[
              Column(
                children: <Widget>[
                  SizedBox(height: 200),
                  MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104),
                ],
              ),
              SizedBox.expand(),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await showContent(tester);

      return pages;
    }

    /// A finger crossing the screen the way a finger does — in small steps, not in one jump. The
    /// step matters: whoever reaches its own slop on an earlier step closes the arena, and a block
    /// that waits for 18 never gets to answer a parent that is done at 8.
    Future<void> dragBy(WidgetTester tester, Offset start, double distance) async {
      final TestGesture gesture = await tester.startGesture(start);
      for (double moved = 0; moved < distance.abs(); moved += 4) {
        await gesture.moveBy(Offset(4 * distance.sign, 0));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('A drag on the block is the block\'s, and the page stays where it is',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final PageController pages = await showBlockInPageView(tester);

        await dragBy(tester, tester.getCenter(find.byType(AndroidView)), -600);

        expect(pages.page, 0);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('A drag beside the block still turns the page', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final PageController pages = await showBlockInPageView(tester);

        final Offset besideTheBlock = tester.getCenter(find.byType(AndroidView)) - const Offset(0, 150);
        await dragBy(tester, besideTheBlock, -600);

        expect(pages.page, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('A block still loading leaves the drag to the page', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final PageController pages = PageController();
        addTearDown(pages.dispose);

        await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(gestureSettings: settings),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: PageView(
              controller: pages,
              children: const <Widget>[
                Column(
                  children: <Widget>[
                    SizedBox(height: 200),
                    MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104),
                  ],
                ),
                SizedBox.expand(),
              ],
            ),
          ),
        ));
        await tester.pumpAndSettle();

        await dragBy(tester, tester.getCenter(find.byType(AndroidView)), -600);

        expect(pages.page, 1);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
  group('A lazy list', () {
    late List<String> methods;
    late List<bool> hostVisible;

    setUp(() {
      methods = <String>[];
      hostVisible = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        if (call.method != 'create') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
        final int viewId = arguments['id']! as int;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(embeddedBlockChannelName(viewId)),
          (MethodCall call) async {
            methods.add(call.method);
            if (call.method == EmbeddedBlockMethods.setHostVisible) {
              hostVisible.add(call.arguments as bool);
            }
            return null;
          },
        );
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    void testOn(TargetPlatform platform, String description,
        Future<void> Function(WidgetTester) body) {
      testWidgets(description, (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = platform;
        try {
          await body(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    // Both platforms host a native block, and the widget's keep-alive and hidden/shown paths
    // are the same Dart on both — only the teardown differs: on iOS the widget sends `release`
    // itself, on Android the platform view's own dispose hook does, so `release` is asserted
    // on iOS only.
    void testOnBoth(String description, Future<void> Function(WidgetTester) body) {
      for (final TargetPlatform platform in <TargetPlatform>[
        TargetPlatform.iOS,
        TargetPlatform.android,
      ]) {
        testOn(platform, '$description (${platform.name})', body);
      }
    }

    // A row that asks to be kept alive on its own, the way a host's stateful row widget might.
    Widget keptRow({required Widget child}) => _KeptAliveRow(child: child);

    // A list ten screens tall with the block in its first row. The test viewport is 600 logical
    // pixels high and the list caches 250 more, so a scroll of a few thousand takes the row far
    // past anything the list keeps around on its own.
    Future<void> pumpList(WidgetTester tester, {required bool keepAlive}) {
      return tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) => index == 0
              ? MindboxEmbeddedBlock(
                  placeSystemName: 'stories',
                  height: 104,
                  keepAlive: keepAlive,
                )
              : const SizedBox(height: 104),
        ),
      ));
    }

    Future<void> scrollBy(WidgetTester tester, double offset) async {
      await tester.drag(find.byType(ListView), Offset(0, -offset));
      await tester.pumpAndSettle();
    }

    int nativeBlocksCreated() =>
        methods.where((String method) => method == EmbeddedBlockMethods.sync).length;

    testOnBoth('A block scrolled away survives the row and comes back without a reload',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();
      expect(nativeBlocksCreated(), 1);

      await scrollBy(tester, 5000);

      expect(find.byType(MindboxEmbeddedBlock), findsNothing);
      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsOneWidget);
      expect(methods, isNot(contains(EmbeddedBlockMethods.release)));

      await scrollBy(tester, -5000);

      expect(find.byType(MindboxEmbeddedBlock), findsOneWidget);
      expect(nativeBlocksCreated(), 1);
      expect(methods, isNot(contains(EmbeddedBlockMethods.release)));
    });

    testOnBoth('A host that opts out gets the block disposed with its row and rebuilt on the way back',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: false);
      await tester.pumpAndSettle();
      expect(nativeBlocksCreated(), 1);

      await scrollBy(tester, 5000);

      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsNothing);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(methods, contains(EmbeddedBlockMethods.release));
      }

      await scrollBy(tester, -5000);

      expect(find.byType(MindboxEmbeddedBlock), findsOneWidget);
      expect(nativeBlocksCreated(), 2);
    });

    testOnBoth('Opting out of keep-alive takes effect on the live block',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();

      await pumpList(tester, keepAlive: false);
      await tester.pumpAndSettle();

      await scrollBy(tester, 5000);

      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsNothing);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(methods, contains(EmbeddedBlockMethods.release));
      }
    });

    testOnBoth('A kept block scrolled out of view is reported hidden, and shown again on the way back',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();
      expect(hostVisible, <bool>[true]);

      await scrollBy(tester, 5000);

      expect(hostVisible, <bool>[true, false]);

      await scrollBy(tester, -5000);

      expect(hostVisible, <bool>[true, false, true]);
    });

    testOnBoth('A kept block still in view is not reported hidden by the check',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();

      // Short of the cache extent: the row is out of the viewport but still live, and a live row
      // is for the platform to pause, not the widget.
      await scrollBy(tester, 150);
      await tester.pump();
      await tester.pump();

      expect(hostVisible, <bool>[true]);
    });

    testOnBoth('Outside a lazy list the check never hides the block', (WidgetTester tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await tester.pump();
      await tester.pump();

      expect(hostVisible, <bool>[true]);
    });

    testOnBoth('A block in a carousel inside a feed is reported hidden when the feed parks the row',
        (WidgetTester tester) async {
      const Key feed = Key('feed');
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          key: feed,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) => index == 0
              ? SizedBox(
                  height: 104,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const <Widget>[
                      SizedBox(
                        width: 300,
                        child: MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104),
                      ),
                      SizedBox(width: 300),
                    ],
                  ),
                )
              : const SizedBox(height: 104),
        ),
      ));
      await tester.pumpAndSettle();
      expect(hostVisible, <bool>[true]);

      // The carousel's own parent data never parks the block — the feed does, one level up.
      await tester.drag(find.byKey(feed), const Offset(0, -5000));
      await tester.pumpAndSettle();

      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsOneWidget);
      expect(hostVisible, <bool>[true, false]);

      await tester.drag(find.byKey(feed), const Offset(0, 5000));
      await tester.pumpAndSettle();

      expect(hostVisible, <bool>[true, false, true]);
    });

    testOnBoth('Opting out while parked lets the list drop the block without showing it first',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();
      await scrollBy(tester, 5000);
      expect(hostVisible, <bool>[true, false]);

      await pumpList(tester, keepAlive: false);
      await tester.pumpAndSettle();

      expect(hostVisible, <bool>[true, false]);
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        expect(methods, contains(EmbeddedBlockMethods.release));
      }
      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsNothing);
    });

    testOnBoth('A block behind a disabled TickerMode stays hidden through parking and return',
        (WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: TickerMode(
          enabled: false,
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) => index == 0
                ? const MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104)
                : const SizedBox(height: 104),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(hostVisible, <bool>[false]);

      await scrollBy(tester, 5000);
      await scrollBy(tester, -5000);

      expect(hostVisible, <bool>[false]);
    });

    Future<void> pumpKeptRowList(WidgetTester tester, {required bool keepAlive}) {
      return tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) => index == 0
              ? keptRow(
                  child: MindboxEmbeddedBlock(
                    placeSystemName: 'stories',
                    height: 104,
                    keepAlive: keepAlive,
                  ),
                )
              : const SizedBox(height: 104),
        ),
      ));
    }

    testOnBoth('A block that opted out but sits in a row someone else keeps is still hidden and shown',
        (WidgetTester tester) async {
      await pumpKeptRowList(tester, keepAlive: false);
      await tester.pumpAndSettle();
      expect(hostVisible, <bool>[true]);

      await scrollBy(tester, 5000);

      // The row's own client keeps it, so the block survives without asking — and must not run.
      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsOneWidget);
      expect(methods, isNot(contains(EmbeddedBlockMethods.release)));
      expect(hostVisible, <bool>[true, false]);

      await scrollBy(tester, -5000);

      expect(hostVisible, <bool>[true, false, true]);
      expect(nativeBlocksCreated(), 1);
    });

    testOnBoth('Opting out while parked in a row someone else keeps does not leave the block hidden',
        (WidgetTester tester) async {
      await pumpKeptRowList(tester, keepAlive: true);
      await tester.pumpAndSettle();
      await scrollBy(tester, 5000);
      expect(hostVisible, <bool>[true, false]);

      await pumpKeptRowList(tester, keepAlive: false);
      await tester.pumpAndSettle();
      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsOneWidget);

      await scrollBy(tester, -5000);

      expect(hostVisible, <bool>[true, false, true]);
      expect(nativeBlocksCreated(), 1);
    });

    testOnBoth('Opting back into keep-alive takes effect on the live block',
        (WidgetTester tester) async {
      await pumpList(tester, keepAlive: false);
      await tester.pumpAndSettle();

      await pumpList(tester, keepAlive: true);
      await tester.pumpAndSettle();

      await scrollBy(tester, 5000);

      expect(find.byType(MindboxEmbeddedBlock, skipOffstage: false), findsOneWidget);
      expect(methods, isNot(contains(EmbeddedBlockMethods.release)));
    });
  });

}

/// A list row with a keep-alive client of its own, as a host's stateful row widget might have.
class _KeptAliveRow extends StatefulWidget {
  const _KeptAliveRow({required this.child});

  final Widget child;

  @override
  State<_KeptAliveRow> createState() => _KeptAliveRowState();
}

class _KeptAliveRowState extends State<_KeptAliveRow> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

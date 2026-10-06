import 'dart:async';

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

/// The plugin channel answering the first look of an `automatic` block with [word] — the SDK's
/// memory of the place, as the native side reads it. A placeholder is what every block used to
/// start with, and what the groups about the block's life after it took its space still assume.
void answerFirstLookWith(String word) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel(embeddedBlockPluginChannelName),
    (MethodCall call) async =>
        call.method == EmbeddedBlockMethods.initialAppearance ? word : null,
  );
}

void forgetFirstLook() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel(embeddedBlockPluginChannelName), null);
}

void main() {
  group('On a platform without a native block', () {
    testWithoutNativeBlock('The block collapses and reports a failure of the SDK\'s own',
        (WidgetTester tester) async {
      final List<MindboxEmbeddedBlockFailReason> fails = <MindboxEmbeddedBlockFailReason>[];
      int loads = 0;
      int empties = 0;

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            loadingStrategy: MindboxEmbeddedBlockLoadingStrategy.placeholder,
            onLoad: () => loads++,
            onEmpty: () => empties++,
            onFail: fails.add,
          ),
        ),
      ));

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 104);

      await tester.pump();

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
      expect(fails, <MindboxEmbeddedBlockFailReason>[MindboxEmbeddedBlockFailReason.internalError]);
      expect(loads, 0);
      expect(empties, 0);
    });

    testWithoutNativeBlock('A block that waits for the SDK\'s word never takes space there',
        (WidgetTester tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(placeSystemName: 'stories', height: 104),
        ),
      ));

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);

      await tester.pump();

      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
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
                onFail: (_) => fails++,
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
            loadingStrategy: MindboxEmbeddedBlockLoadingStrategy.placeholder,
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
                onFail: (_) => fails++,
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

    testWithoutNativeBlock('A budget changed after creation is ignored, and said out loud once per new value',
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
        await buildWith(const Duration(seconds: 12));
      } finally {
        debugPrint = printed;
      }

      // One line per value given, as the Compose wrapper says it: the repeat of 12 adds nothing.
      expect(log.where((String line) => line.contains('timeout')), hasLength(2));
      expect(log.first, contains('"stories"'));
      expect(log.first, contains('given timeout 0:00:09'));
      expect(log.first, contains('keeps 0:00:05'));
      expect(log.last, contains('given timeout 0:00:12'));
    });

    testWithoutNativeBlock('A strategy or an animation flag changed after creation is ignored, and said out loud once per new value',
        (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');

      try {
        Future<void> buildWith(MindboxEmbeddedBlockLoadingStrategy strategy, bool animates) =>
            tester.pumpWidget(Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: MindboxEmbeddedBlock(
                  placeSystemName: 'stories',
                  height: 104,
                  loadingStrategy: strategy,
                  animatesReveal: animates,
                ),
              ),
            ));

        await buildWith(MindboxEmbeddedBlockLoadingStrategy.hidden, true);
        expect(log, isEmpty);

        await buildWith(MindboxEmbeddedBlockLoadingStrategy.placeholder, false);
        await buildWith(MindboxEmbeddedBlockLoadingStrategy.automatic, false);
        await buildWith(MindboxEmbeddedBlockLoadingStrategy.automatic, false);
      } finally {
        debugPrint = printed;
      }

      // Two strategies given, one flag given: three lines, and the repeated rebuild adds nothing.
      expect(log, hasLength(3));
      expect(log[0], contains('given loadingStrategy MindboxEmbeddedBlockLoadingStrategy.placeholder'));
      expect(log[0], contains('keeps MindboxEmbeddedBlockLoadingStrategy.hidden'));
      expect(log[1], contains('animatesReveal'));
      expect(log[1], contains('keeps true'));
      expect(log[2], contains('given loadingStrategy MindboxEmbeddedBlockLoadingStrategy.automatic'));
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

  group('The strategy and the animation flag', () {
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
      WidgetTester tester, {
      MindboxEmbeddedBlockLoadingStrategy? strategy,
      bool? animatesReveal,
    }) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: 'stories',
              height: 104,
              loadingStrategy: strategy ?? MindboxEmbeddedBlockLoadingStrategy.automatic,
              animatesReveal: animatesReveal ?? true,
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

    testWidgets('Reach the native block as the words every platform reads',
        (WidgetTester tester) async {
      final Map<Object?, Object?> params = await paramsOf(
        tester,
        strategy: MindboxEmbeddedBlockLoadingStrategy.hidden,
        animatesReveal: false,
      );

      expect(params['loadingStrategy'], 'hidden');
      expect(params['animatesReveal'], false);
    });

    testWidgets('Default to automatic and animated, said explicitly', (WidgetTester tester) async {
      final Map<Object?, Object?> params = await paramsOf(tester);

      expect(params['loadingStrategy'], 'automatic');
      expect(params['animatesReveal'], true);
    });

    testWidgets('Every strategy has a word', (WidgetTester tester) async {
      for (final MindboxEmbeddedBlockLoadingStrategy strategy
          in MindboxEmbeddedBlockLoadingStrategy.values) {
        // The strategy is fixed at creation, so every word needs a block of its own.
        await tester.pumpWidget(const SizedBox.shrink());
        created.clear();
        final Map<Object?, Object?> params = await paramsOf(tester, strategy: strategy);
        expect(params['loadingStrategy'], strategy.name, reason: '$strategy');
      }
    });
  });

  group('The first look', () {
    late int viewId;
    late List<Map<Object?, Object?>> created;
    late List<Map<Object?, Object?>> asked;
    Completer<String>? firstLook;

    setUp(() {
      viewId = -1;
      created = <Map<Object?, Object?>>[];
      asked = <Map<Object?, Object?>>[];
      firstLook = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        // Only these two carry a map; `dispose` sends the bare view id.
        if (call.method != 'create' && call.method != 'resize') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
        if (call.method == 'resize') {
          return <Object?, Object?>{'width': arguments['width'], 'height': arguments['height']};
        }

        viewId = arguments['id']! as int;
        final Uint8List params = arguments['params'] as Uint8List;
        created.add(const StandardMessageCodec().decodeMessage(
          params.buffer.asByteData(params.offsetInBytes, params.lengthInBytes),
        ) as Map<Object?, Object?>);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          MethodChannel(embeddedBlockChannelName(viewId)),
          (MethodCall call) async => null,
        );
        return 0;
      });
      // The plugin answers when the test says so: what the block does before the answer is the
      // point of half of these tests. The completer is born here, inside the test's zone — one
      // made in setUp lives in the runner's zone, and its answer would reach the block only once
      // the test body is over.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(embeddedBlockPluginChannelName),
        (MethodCall call) {
          asked.add(call.arguments as Map<Object?, Object?>);
          final Completer<String> answer = Completer<String>();
          firstLook = answer;
          return answer.future;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
      forgetFirstLook();
    });

    Future<void> show(
      WidgetTester tester, {
      MindboxEmbeddedBlockLoadingStrategy strategy = MindboxEmbeddedBlockLoadingStrategy.automatic,
    }) =>
        tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: 'stories',
              height: 104,
              loadingStrategy: strategy,
              placeholder: (_) => const SizedBox.expand(key: Key('host-placeholder')),
            ),
          ),
        ));

    Future<void> report(WidgetTester tester, Map<String, Object> arguments) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        embeddedBlockChannelName(viewId),
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(EmbeddedBlockMethods.report, arguments),
        ),
        (ByteData? _) {},
      );
      await tester.pump();
    }

    double slotHeight(WidgetTester tester) => tester.getSize(find.byType(MindboxEmbeddedBlock)).height;

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

    testOn(TargetPlatform.iOS, 'A placeholder block takes its height from the first frame and asks nobody',
        (WidgetTester tester) async {
      await show(tester, strategy: MindboxEmbeddedBlockLoadingStrategy.placeholder);

      expect(slotHeight(tester), 104);
      expect(find.byKey(const Key('host-placeholder')), findsOneWidget);
      expect(asked, isEmpty);
    });

    testOn(TargetPlatform.android,
        'A hidden block takes no space from the first frame, while its native block is built with its full height',
        (WidgetTester tester) async {
      await show(tester, strategy: MindboxEmbeddedBlockLoadingStrategy.hidden);
      expect(slotHeight(tester), 0);
      expect(find.byKey(const Key('host-placeholder')), findsNothing);
      await tester.pumpAndSettle();

      // Sized to nothing, the platform view would never be created on Android; sized to its
      // height under a clipped slot of zero, it is — and the block can load unseen and grow.
      expect(created, hasLength(1));
      expect(tester.getSize(find.byType(AndroidView)).height, 104);
      expect(slotHeight(tester), 0);
      expect(asked, isEmpty);
    });

    testOn(TargetPlatform.iOS, 'An automatic block asks the plugin for the place\'s first look, once',
        (WidgetTester tester) async {
      await show(tester);
      await tester.pumpAndSettle();
      await show(tester);
      await tester.pumpAndSettle();

      expect(asked, <Map<Object?, Object?>>[
        <Object?, Object?>{'placeSystemName': 'stories', 'loadingStrategy': 'automatic'},
      ]);
    });

    testOn(TargetPlatform.iOS,
        'An automatic block takes no space until the plugin answers, and opens for a place that showed content before',
        (WidgetTester tester) async {
      await show(tester);
      expect(slotHeight(tester), 0);
      await tester.pumpAndSettle();
      expect(slotHeight(tester), 0);

      firstLook!.complete('placeholder');
      await tester.pumpAndSettle();

      expect(slotHeight(tester), 104);
      expect(find.byKey(const Key('host-placeholder')), findsOneWidget);
    });

    testOn(TargetPlatform.iOS, 'An automatic block stays hidden for a place that never showed content',
        (WidgetTester tester) async {
      await show(tester);
      firstLook!.complete('collapsed');
      await tester.pumpAndSettle();

      expect(slotHeight(tester), 0);
      expect(find.byKey(const Key('host-placeholder')), findsNothing);
    });

    testOn(TargetPlatform.iOS, 'The native block\'s own report outranks an answer that comes later',
        (WidgetTester tester) async {
      await show(tester);
      await tester.pumpAndSettle();
      await report(tester, <String, Object>{'appearance': 'content'});
      expect(slotHeight(tester), 104);

      firstLook!.complete('collapsed');
      await tester.pumpAndSettle();

      expect(slotHeight(tester), 104);
    });

    testOn(TargetPlatform.iOS, 'A plugin that cannot answer leaves the block to its own report, and says so',
        (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');
      try {
        await show(tester);
        firstLook!.completeError(PlatformException(code: 'bad_arguments'));
        await tester.pumpAndSettle();
        expect(slotHeight(tester), 0);

        await report(tester, <String, Object>{'appearance': 'placeholder'});
      } finally {
        debugPrint = printed;
      }

      expect(slotHeight(tester), 104);
      expect(log.where((String line) => line.contains('initialAppearance')), hasLength(1));
    });
  });

  group('The reveal', () {
    late int viewId;

    setUp(() {
      viewId = -1;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        if (call.method != 'create') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
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

    Future<void> show(
      WidgetTester tester,
      MindboxEmbeddedBlockLoadingStrategy strategy, {
      WidgetBuilder? placeholder,
      WidgetBuilder? errorBuilder,
    }) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            loadingStrategy: strategy,
            placeholder: placeholder,
            errorBuilder: errorBuilder,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> report(WidgetTester tester, Map<String, Object> arguments) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        embeddedBlockChannelName(viewId),
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(EmbeddedBlockMethods.report, arguments),
        ),
        (ByteData? _) {},
      );
      await tester.pump();
    }

    double slotHeight(WidgetTester tester) => tester.getSize(find.byType(MindboxEmbeddedBlock)).height;

    void testOnIOS(String description, Future<void> Function(WidgetTester) body) {
      testWidgets(description, (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await body(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    // Not the SDK's own 250: a wrapper that ignored the duration it was sent would still pass
    // against the default.
    const Map<String, Object> animatedContent = <String, Object>{
      'appearance': 'content',
      'animated': true,
      'revealDurationMs': 400,
    };

    const Key hostPlaceholder = Key('host-placeholder');
    const Key hostError = Key('host-error');
    Widget hostPlaceholderScreen(BuildContext _) => const SizedBox.expand(key: hostPlaceholder);
    Widget hostErrorScreen(BuildContext _) => const SizedBox.expand(key: hostError);

    testOnIOS('A hidden block grows to its height over the SDK\'s reveal when the native block says so',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.hidden);
      expect(slotHeight(tester), 0);

      await report(tester, animatedContent);
      expect(slotHeight(tester), 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(slotHeight(tester), closeTo(52, 1));

      await tester.pump(const Duration(milliseconds: 200));
      expect(slotHeight(tester), 104);
      expect(tester.getSize(find.byType(UiKitView)).height, 104);
    });

    testOnIOS('Without the native block\'s word the content lands at once', (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.hidden);

      await report(tester, <String, Object>{'appearance': 'content'});

      expect(slotHeight(tester), 104);
    });

    testOnIOS('A reveal that names no duration lands at once', (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.hidden);

      await report(tester, <String, Object>{'appearance': 'content', 'animated': true});

      expect(slotHeight(tester), 104);
    });

    testOnIOS('Content arriving into a placeholder has its height already: nothing grows',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.placeholder);
      expect(slotHeight(tester), 104);

      await report(tester, animatedContent);

      expect(slotHeight(tester), 104);
    });

    testOnIOS('A collapse lands at once, even mid-reveal', (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.hidden);
      await report(tester, animatedContent);
      await tester.pump(const Duration(milliseconds: 100));
      expect(slotHeight(tester), greaterThan(0));

      await report(tester, <String, Object>{'appearance': 'collapsed'});

      expect(slotHeight(tester), 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(slotHeight(tester), 0);
    });

    for (final String look in <String>['error', 'placeholder']) {
      testOnIOS('A $look arriving mid-growth takes the full height at once', (WidgetTester tester) async {
        await show(tester, MindboxEmbeddedBlockLoadingStrategy.hidden, errorBuilder: hostErrorScreen);
        await report(tester, animatedContent);
        await tester.pump(const Duration(milliseconds: 100));
        final double midway = slotHeight(tester);
        expect(midway, greaterThan(0));
        expect(midway, lessThan(104));

        await report(tester, <String, Object>{'appearance': look});

        expect(slotHeight(tester), 104);
        await tester.pump(const Duration(milliseconds: 150));
        expect(slotHeight(tester), 104);
      });
    }

    testOnIOS('Content arriving animated fades the host\'s placeholder out over the reveal, untouchable',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.placeholder,
          placeholder: hostPlaceholderScreen);
      expect(find.byKey(hostPlaceholder), findsOneWidget);

      await report(tester, animatedContent);

      expect(find.byKey(hostPlaceholder), findsOneWidget);
      expect(find.ancestor(of: find.byKey(hostPlaceholder), matching: find.byType(IgnorePointer)),
          findsOneWidget);
      final FadeTransition fade = tester.widget(
          find.ancestor(of: find.byKey(hostPlaceholder), matching: find.byType(FadeTransition)));
      expect(fade.opacity.value, 1);

      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(hostPlaceholder), findsOneWidget);
      expect(fade.opacity.value, lessThan(1));
      expect(fade.opacity.value, greaterThan(0));

      // The fade is over once the clock is past its 400 ms, and the layer leaves on the next build.
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(find.byKey(hostPlaceholder), findsNothing);
      expect(find.byType(FadeTransition), findsNothing);
    });

    testOnIOS('The host\'s error screen replaced by content fades out the same way',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.placeholder, errorBuilder: hostErrorScreen);
      await report(tester, <String, Object>{'appearance': 'error'});
      expect(find.byKey(hostError), findsOneWidget);

      await report(tester, animatedContent);
      expect(find.byKey(hostError), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(find.byKey(hostError), findsNothing);
    });

    testOnIOS('Without the native block\'s word the host\'s placeholder goes at once',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.placeholder,
          placeholder: hostPlaceholderScreen);

      await report(tester, <String, Object>{'appearance': 'content'});

      expect(find.byKey(hostPlaceholder), findsNothing);
    });

    testOnIOS('A look arriving mid-fade takes the fading layer down at once',
        (WidgetTester tester) async {
      await show(tester, MindboxEmbeddedBlockLoadingStrategy.placeholder,
          placeholder: hostPlaceholderScreen);
      await report(tester, animatedContent);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(hostPlaceholder), findsOneWidget);

      await report(tester, <String, Object>{'appearance': 'collapsed'});

      expect(find.byKey(hostPlaceholder), findsNothing);
      expect(slotHeight(tester), 0);
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

    // The native blocks ignore the padding themselves, so the widget neither trims the name nor
    // warns about it: a name pasted with a stray space finds its place, and the log stays quiet.
    testWidgets('Reaches the native block as given, and says nothing about it',
        (WidgetTester tester) async {
      final List<String> log = <String>[];
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) => log.add(message ?? '');
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      try {
        await tester.pumpWidget(const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: MindboxEmbeddedBlock(
              placeSystemName: ' stories ',
              height: 104,
              loadingStrategy: MindboxEmbeddedBlockLoadingStrategy.placeholder,
            ),
          ),
        ));
        await tester.pumpAndSettle();
      } finally {
        debugPrint = printed;
        debugDefaultTargetPlatformOverride = null;
      }

      expect(created.single['placeSystemName'], ' stories ');
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
      answerFirstLookWith('placeholder');
      addTearDown(forgetFirstLook);
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

    testWidgets('A block created with no height builds no native block', (WidgetTester tester) async {
      answerFirstLookWith('placeholder');
      addTearDown(forgetFirstLook);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final DebugPrintCallback printed = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
      try {
        await buildWith(tester, 0);
        await tester.pumpAndSettle();

        expect(created, isEmpty);
        expect(find.byType(AndroidView), findsNothing);
      } finally {
        debugPrint = printed;
        debugDefaultTargetPlatformOverride = null;
      }
    });

    /// `height` is live and promises no reload: a block the host collapses to nothing and opens
    /// again keeps its native block and the page behind it, rather than building both anew.
    testWidgets('A live block passing through a height of nothing keeps its native block',
        (WidgetTester tester) async {
      answerFirstLookWith('placeholder');
      addTearDown(forgetFirstLook);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await buildWith(tester, 104);
        await tester.pumpAndSettle();
        expect(created, hasLength(1));

        await buildWith(tester, 0);
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
        expect(find.byType(AndroidView), findsOneWidget);

        await buildWith(tester, 104);
        await tester.pumpAndSettle();

        expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 104);
        expect(created, hasLength(1));
      } finally {
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

  group('The outcome', () {
    late int viewId;
    late List<String> heard;

    setUp(() {
      viewId = -1;
      heard = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, (MethodCall call) async {
        if (call.method != 'create') {
          return null;
        }

        final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;
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

    /// A native block with every callback listening; what each one hears goes to [heard].
    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            onLoad: () => heard.add('load'),
            onEmpty: () => heard.add('empty'),
            onFail: (MindboxEmbeddedBlockFailReason reason) => heard.add('fail:$reason'),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// The native block reporting on its channel, the way the platform view does.
    Future<void> report(WidgetTester tester, Map<String, Object> arguments) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        embeddedBlockChannelName(viewId),
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(EmbeddedBlockMethods.report, arguments),
        ),
        (ByteData? _) {},
      );
      await tester.pump();
    }

    // The delivery is the same Dart on both platforms; iOS is picked for the plainer mock — a
    // UiKitView is created without the resize round trip an AndroidView needs answered.
    void testOnIOS(String description, Future<void> Function(WidgetTester) body) {
      testWidgets(description, (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
          await body(tester);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }

    testOnIOS('An empty place is reported as empty, not as a failure', (WidgetTester tester) async {
      await show(tester);
      await report(tester, <String, Object>{'appearance': 'collapsed', 'outcome': 'empty'});

      expect(heard, <String>['empty']);
      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 0);
    });

    testOnIOS('A failure carries its reason', (WidgetTester tester) async {
      await show(tester);
      await report(tester, <String, Object>{
        'appearance': 'collapsed',
        'outcome': 'fail',
        'reason': 'networkError',
      });

      expect(heard, <String>['fail:networkError']);
    });

    testOnIOS('A reason this version does not know is passed through as it is',
        (WidgetTester tester) async {
      MindboxEmbeddedBlockFailReason? reason;
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: MindboxEmbeddedBlock(
            placeSystemName: 'stories',
            height: 104,
            onFail: (MindboxEmbeddedBlockFailReason heardReason) => reason = heardReason,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await report(tester, <String, Object>{'outcome': 'fail', 'reason': 'sideways'});

      expect(reason, const MindboxEmbeddedBlockFailReason('sideways'));
      expect(reason, isNot(MindboxEmbeddedBlockFailReason.internalError));
    });

    testOnIOS('A failure without a reason is the SDK\'s own error', (WidgetTester tester) async {
      await show(tester);
      await report(tester, <String, Object>{'appearance': 'collapsed', 'outcome': 'fail'});

      expect(heard, <String>['fail:internalError']);
    });

    testOnIOS('A failure that repeats with another reason is the same outcome',
        (WidgetTester tester) async {
      await show(tester);
      await report(tester, <String, Object>{'outcome': 'fail', 'reason': 'networkError'});
      await report(tester, <String, Object>{'outcome': 'fail', 'reason': 'internalError'});

      expect(heard, <String>['fail:networkError']);
    });

    testOnIOS('An outcome that changed is delivered again, a repeated one is not',
        (WidgetTester tester) async {
      await show(tester);
      await report(tester, <String, Object>{'outcome': 'empty'});
      await report(tester, <String, Object>{'outcome': 'empty'});
      await report(tester, <String, Object>{'outcome': 'load'});
      await report(tester, <String, Object>{'outcome': 'fail', 'reason': 'networkError'});

      expect(heard, <String>['empty', 'load', 'fail:networkError']);
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
      answerFirstLookWith('placeholder');
      addTearDown(forgetFirstLook);
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
      answerFirstLookWith('placeholder');
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
      forgetFirstLook();
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

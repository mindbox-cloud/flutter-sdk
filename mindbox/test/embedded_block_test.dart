import 'package:flutter/foundation.dart';
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
}

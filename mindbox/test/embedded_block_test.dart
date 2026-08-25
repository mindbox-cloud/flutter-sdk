import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';

/// Runs [body] on a platform the block has no native half for.
///
/// The override is cleared inside the test rather than in a `tearDown`: `flutter_test` checks the
/// foundation debug variables on the way out of the body, before any teardown runs.

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
  // The widget draws a platform view on iOS and Android, and neither exists in a widget test. What
  // is checked here is the part written once and read the same on every platform: the layout the
  // block hands back, the screens the host draws, and the outcome it hears.
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

      // The space is taken before anything is known about the place.
      expect(tester.getSize(find.byType(MindboxEmbeddedBlock)).height, 104);

      await tester.pump();

      // And handed back once it turns out there is no block behind it.
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

      // Everything remembered about the old block goes with it: the new one reports its own outcome.
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

      // Once, however many times the host tries: a widget rebuilt every frame would otherwise fill
      // the log with the same line.
      expect(log.where((String line) => line.contains('timeout')), hasLength(1));
      expect(log.single, contains('"stories"'));
      expect(log.single, contains('0:00:05'));
    });
  });

  // What the host asks for has to reach the native container, and that is the one thing a widget
  // test can still see of it: the creation params the platform view is built with.
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
        // The view's own window into the buffer, not the whole buffer: the engine hands over a
        // slice, and decoding from byte zero of what it is a slice of reads somebody else's message.
        created.add(const StandardMessageCodec().decodeMessage(
          params.buffer.asByteData(params.offsetInBytes, params.lengthInBytes),
        ) as Map<Object?, Object?>);
        // A texture id, which is what the Android controller reads back and casts. iOS ignores the
        // answer, so one number serves both.
        return 0;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform_views, null);
    });

    /// Builds a block on [platform] — the only two the widget has a native half for — and hands back
    /// the params its platform view was created with.
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

        // Absent, not zero: there is no number that means "no budget", and a native side that finds
        // nothing keeps its own 30 seconds.
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

      // Not a budget any block could survive — and not Dart's call: both native containers already
      // fall back to their default and log what they were given, and second-guessing that here
      // would put the same rule in three places, spelled three ways.
      expect(params['timeoutMs'], 0);
    });
  });
}

import 'package:flutter/foundation.dart';
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
  });
}

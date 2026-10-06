import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/src/embedded_block.dart';

void main() {
  group('Channel naming', () {
    test('Every created block gets a channel of its own', () {
      expect(embeddedBlockChannelName(0), '$embeddedBlockViewType/0');
      expect(embeddedBlockChannelName(7), '$embeddedBlockViewType/7');
      expect(embeddedBlockChannelName(1) == embeddedBlockChannelName(2), isFalse);
    });

    test('The view type is the one both native factories register', () {
      expect(embeddedBlockViewType, 'mindbox.cloud/flutter-sdk/embedded_block');
    });

    test('The plugin channel is shared, and no view id can collide with it', () {
      expect(embeddedBlockPluginChannelName, '$embeddedBlockViewType/plugin');
      expect(embeddedBlockPluginChannelName, isNot(embeddedBlockChannelName(0)));
    });
  });

  group('The words on the wire', () {
    test('The creation params and the first-look question are spelled as the native sides read them',
        () {
      expect(EmbeddedBlockParams.loadingStrategy, 'loadingStrategy');
      expect(EmbeddedBlockParams.animatesReveal, 'animatesReveal');
      expect(EmbeddedBlockMethods.initialAppearance, 'initialAppearance');
    });

    test('An appearance word is read the same way on its own as inside a report', () {
      expect(EmbeddedBlockReport.appearanceOf('content'), EmbeddedBlockAppearance.content);
      expect(EmbeddedBlockReport.appearanceOf('collapsed'), EmbeddedBlockAppearance.collapsed);
      expect(EmbeddedBlockReport.appearanceOf('sideways'), isNull);
      expect(EmbeddedBlockReport.appearanceOf(null), isNull);
    });
  });

  group('EmbeddedBlockReport.tryParse', () {
    test('Reads both parts of a full report', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'content', 'outcome': 'load'},
      );

      expect(report, isNotNull);
      expect(report!.appearance, EmbeddedBlockAppearance.content);
      expect(report.outcome, EmbeddedBlockOutcome.load);
    });

    test('Every appearance the native side can send is understood', () {
      const Map<String, EmbeddedBlockAppearance> wire =
          <String, EmbeddedBlockAppearance>{
        'placeholder': EmbeddedBlockAppearance.placeholder,
        'content': EmbeddedBlockAppearance.content,
        'error': EmbeddedBlockAppearance.error,
        'collapsed': EmbeddedBlockAppearance.collapsed,
      };

      wire.forEach((String word, EmbeddedBlockAppearance expected) {
        final EmbeddedBlockReport? report =
            EmbeddedBlockReport.tryParse(<String, Object>{'appearance': word});
        expect(report?.appearance, expected, reason: word);
      });
      expect(wire.length, EmbeddedBlockAppearance.values.length);
    });

    test('An absent outcome is not an outcome', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'placeholder'},
      );

      expect(report?.appearance, EmbeddedBlockAppearance.placeholder);
      expect(report?.outcome, isNull);
    });

    test('Every outcome the native side can send is understood', () {
      const Map<String, EmbeddedBlockOutcome> wire = <String, EmbeddedBlockOutcome>{
        'load': EmbeddedBlockOutcome.load,
        'empty': EmbeddedBlockOutcome.empty,
        'fail': EmbeddedBlockOutcome.fail,
      };

      wire.forEach((String word, EmbeddedBlockOutcome expected) {
        final EmbeddedBlockReport? report =
            EmbeddedBlockReport.tryParse(<String, Object>{'outcome': word});
        expect(report?.outcome, expected, reason: word);
      });
      expect(wire.length, EmbeddedBlockOutcome.values.length);
    });

    test('A failure carries its reason as the native side spelled it', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'collapsed', 'outcome': 'fail', 'reason': 'networkError'},
      );

      expect(report?.outcome, EmbeddedBlockOutcome.fail);
      expect(report?.failReason, 'networkError');
    });

    test('A reason is a word or nothing', () {
      expect(
        EmbeddedBlockReport.tryParse(<String, Object>{'outcome': 'fail'})?.failReason,
        isNull,
      );
      expect(
        EmbeddedBlockReport.tryParse(<String, Object>{'outcome': 'fail', 'reason': 7})?.failReason,
        isNull,
      );
    });

    test('The reveal arrives with its duration', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'content', 'animated': true, 'revealDurationMs': 250},
      );

      expect(report?.isRevealAnimated, isTrue);
      expect(report?.revealDuration, const Duration(milliseconds: 250));
    });

    test('A report that is not a reveal says so, whatever else it carries', () {
      expect(
        EmbeddedBlockReport.tryParse(<String, Object>{'appearance': 'content'})?.isRevealAnimated,
        isFalse,
      );
      expect(
        EmbeddedBlockReport.tryParse(<String, Object>{'appearance': 'content'})?.revealDuration,
        isNull,
      );
      expect(
        EmbeddedBlockReport.tryParse(<String, Object>{'animated': 'yes', 'revealDurationMs': '250'}),
        isA<EmbeddedBlockReport>()
            .having((EmbeddedBlockReport r) => r.isRevealAnimated, 'isRevealAnimated', isFalse)
            .having((EmbeddedBlockReport r) => r.revealDuration, 'revealDuration', isNull),
      );
    });

    test('A newer native side may send words this version does not know', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'sideways', 'outcome': 'maybe', 'extra': 1},
      );

      expect(report, isNotNull);
      expect(report!.appearance, isNull);
      expect(report.outcome, isNull);
    });

    test('Anything that is not a map is not a report', () {
      expect(EmbeddedBlockReport.tryParse(null), isNull);
      expect(EmbeddedBlockReport.tryParse('report'), isNull);
      expect(EmbeddedBlockReport.tryParse(<Object>['content']), isNull);
    });
  });
}

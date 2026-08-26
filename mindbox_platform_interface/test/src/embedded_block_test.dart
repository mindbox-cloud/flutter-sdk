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

    test('A failure reads as fail', () {
      final EmbeddedBlockReport? report = EmbeddedBlockReport.tryParse(
        <String, Object>{'appearance': 'collapsed', 'outcome': 'fail'},
      );

      expect(report?.outcome, EmbeddedBlockOutcome.fail);
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

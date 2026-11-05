import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox/mindbox.dart';

void main() {
  group('MindboxEmbeddedBlockFailReason', () {
    test('The raw values are the ones every platform reports', () {
      expect(MindboxEmbeddedBlockFailReason.networkError.rawValue, 'networkError');
      expect(MindboxEmbeddedBlockFailReason.internalError.rawValue, 'internalError');
    });

    test('A reason is its raw value: equal by it, hashed by it, printed as it', () {
      const MindboxEmbeddedBlockFailReason reason = MindboxEmbeddedBlockFailReason('networkError');

      expect(reason, MindboxEmbeddedBlockFailReason.networkError);
      expect(reason.hashCode, MindboxEmbeddedBlockFailReason.networkError.hashCode);
      expect(reason.toString(), 'networkError');
      expect(reason, isNot(MindboxEmbeddedBlockFailReason.internalError));
    });

    test('A word this version does not know is still a reason', () {
      const MindboxEmbeddedBlockFailReason later = MindboxEmbeddedBlockFailReason('quotaExceeded');

      expect(later.rawValue, 'quotaExceeded');
      expect(later, isNot(MindboxEmbeddedBlockFailReason.networkError));
    });
  });
}

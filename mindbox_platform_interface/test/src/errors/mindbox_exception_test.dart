import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/src/errors/mindbox_exception.dart';

void main() {
  test('Constructor Test', () {
    // Arrange
    final MindboxException mindboxException = MindboxException(
        message: 'dummy-message', code: 'dummy-code', details: 'dummy-details');

    // Assert
    expect(mindboxException.message, 'dummy-message');
    expect(mindboxException.code, 'dummy-code');
    expect(mindboxException.details, 'dummy-details');
  });

  test('toString: Should return a message of the exception', () {
    // Arrange
    final MindboxException exception = MindboxException(
      message: 'dummy-message',
    );

    // Act
    final String actual = exception.toString();

    // Assert
    expect(actual, 'dummy-message');
  });

  test('toString: Should return a message and details on new line', () {
    // Arrange
    final MindboxException exception =
    MindboxException(message: 'dummy-message', details: 'dummy-details');

    // Act
    final String actual = exception.toString();

    // Assert
    expect(actual, 'dummy-message\ndummy-details');
  });

  test('toString: Should return a message with code and details on new line',
          () {
        // Arrange
        final MindboxException exception = MindboxException(
          message: 'dummy-message',
          details: 'dummy-details',
          code: 'dummy-code',
        );

        // Act
        final String actual = exception.toString();

        // Assert
        expect(actual, '(code: dummy-code) dummy-message\ndummy-details');
      });

  test('toString: Should return a message with code',
          () {
        // Arrange
        final MindboxException exception = MindboxException(
          message: 'dummy-message',
          code: 'dummy-code',
        );

        // Act
        final String actual = exception.toString();

        // Assert
        expect(actual, '(code: dummy-code) dummy-message');
      });
}

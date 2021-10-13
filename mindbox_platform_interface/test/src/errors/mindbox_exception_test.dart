import 'package:flutter_test/flutter_test.dart';
import 'package:mindbox_platform_interface/src/errors/mindbox_exception.dart';

void main() {
  test('toString: Should return a message of the exception', () {
    // Arrange
    final MindboxException exception = MindboxException(
      message: 'message',
    );

    // Act
    final String actual = exception.toString();

    // Assert
    expect(actual, 'message');
  });

  test('toString: Should return a message and details on new line', () {
    // Arrange
    final MindboxException exception =
        MindboxException(message: 'message', details: 'details');

    // Act
    final String actual = exception.toString();

    // Assert
    expect(actual, 'message\ndetails');
  });
}

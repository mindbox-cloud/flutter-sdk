import 'package:firebase_messaging/firebase_messaging.dart';

/// Check if the message is from Mindbox by looking for 'uniqueKey' in data
bool isMindboxMessage(RemoteMessage remoteMessage) {
  final data = remoteMessage.data;
  if (data == null) return false;

  final uniqueKey = data['uniqueKey'];
  return uniqueKey is String && uniqueKey.isNotEmpty;
}

/// Check if the message is notification-only (no data payload)
bool isNotificationOnly(RemoteMessage message) {
  return message.data.isEmpty && message.notification != null;
}

/// Check if the message is data-only (no notification payload)
bool isDataOnly(RemoteMessage message) {
  return message.data.isNotEmpty && message.notification == null;
}

/// Check if the message is mixed (has both notification and data)
bool isMixedMessage(RemoteMessage message) {
  return message.data.isNotEmpty && message.notification != null;
}
import 'dart:convert';
import 'push_action.dart';
import 'payload.dart';

//example of data by push
class MindboxRemoteMessage {

  MindboxRemoteMessage({
    required this.uniqueKey,
    required this.title,
    required this.description,
    this.pushLink,
    this.imageUrl,
    required this.pushActions,
    this.payload,
  });

  factory MindboxRemoteMessage.fromJson(Map<String, dynamic> json) {
    final pushActionsFromJson = json['pushActions'] as List;
    final List<PushAction> pushActionsList = pushActionsFromJson.map((action) => PushAction.fromJson(action)).toList();

    return MindboxRemoteMessage(
      uniqueKey: json['uniqueKey'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      pushLink: json['pushLink'],
      pushActions: pushActionsList,
      payload: json['payload'],
    );
  }
  final String uniqueKey;
  final String title;
  final String description;
  final String? pushLink;
  final String? imageUrl;
  final List<PushAction> pushActions;
  final String? payload;

  Payload? getPayloadObject() {
    if (payload == null)
      { return null; }
    final Map<String, dynamic> payloadMap = jsonDecode(payload!);
    return Payload.fromJson(payloadMap);
  }
}

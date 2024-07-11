import 'dart:convert';
import 'push_action.dart';
import 'payload.dart';

//example of data by push
class MindboxRemoteMessage {
  final String uniqueKey;
  final String title;
  final String description;
  final String? pushLink;
  final String? imageUrl;
  final List<PushAction> pushActions;
  final String? payload;

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
    var pushActionsFromJson = json['pushActions'] as List;
    List<PushAction> pushActionsList = pushActionsFromJson.map((action) => PushAction.fromJson(action)).toList();

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

  Payload? getPayloadObject() {
    if (payload == null) return null;
    Map<String, dynamic> payloadMap = jsonDecode(payload!);
    return Payload.fromJson(payloadMap);
  }
}

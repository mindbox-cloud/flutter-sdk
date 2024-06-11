import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_example/models/mindbox_remote_message.dart';

typedef ItemsChangedCallback = void Function();

class ItemsManager {
  static const int removeStartIndex = 3;
  final List<MindboxRemoteMessage> items = [
    MindboxRemoteMessage(
      uniqueKey: 'exampleUniqueKey1',
      title: 'Example Title 1',
      description: 'This is an example description for remote message 1.',
      imageUrl: 'https://mobpush-images.mindbox.ru/Mpush-test/1a73ebaa-3e5f-49f4-ae6c-462c9b64d34c/307be696-77e6-4d83-b7eb-c94be85f7a03.png',
      pushLink: 'http://example.com/1',
      pushActions: [],
      payload: '{"pushName":"Push name 1","pushDate":"Push date 1"}',
    ),
    MindboxRemoteMessage(
      uniqueKey: 'exampleUniqueKey2',
      title: 'Example Title 2',
      description: 'This is an example description for remote message 2.',
      imageUrl: 'https://mobpush-images.mindbox.ru/Mpush-test/1a73ebaa-3e5f-49f4-ae6c-462c9b64d34c/2397fea9-383d-49bf-a6a0-181a267faa94.png',
      pushLink: 'http://example.com/2',
      pushActions: [],
      payload: '{"pushName":"Push name 2","pushDate":"Push date 2"}',
    ),
    MindboxRemoteMessage(
      uniqueKey: 'exampleUniqueKey3',
      title: 'Example Title 3',
      description: 'This is an example description for remote message 3.',
      imageUrl: 'https://mobpush-images.mindbox.ru/Mpush-test/1a73ebaa-3e5f-49f4-ae6c-462c9b64d34c/bd4250b1-a7ac-4b8a-b91b-481b3b5c565c.png',
      pushLink: 'http://example.com/3',
      pushActions: [],
      payload: '{"pushName":"Push name 3","pushDate":"Push date 3"}',
    ),
  ];

  ItemsChangedCallback? onItemsChanged;

  Future<void> loadItemsFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    String? storedItemsJson = prefs.getString('notifications');

    if (storedItemsJson != null) {
      List<dynamic> storedItems = jsonDecode(storedItemsJson);
      for (String item in storedItems) {
        MindboxRemoteMessage message = MindboxRemoteMessage.fromJson(
            jsonDecode(item));
        if (!_containsItem(message)) {
          items.add(message);
        }
      }
      onItemsChanged?.call();
    }
  }

  bool _containsItem(MindboxRemoteMessage item) {
    return items.any((element) => element.uniqueKey == item.uniqueKey);
  }

  Future<void> clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    items.removeRange(removeStartIndex, items.length);
    onItemsChanged?.call();
  }
}
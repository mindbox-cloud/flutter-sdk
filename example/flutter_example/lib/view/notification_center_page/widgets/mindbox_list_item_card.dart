import 'package:flutter/material.dart';
import 'package:flutter_example/models/list_item.dart';

import '../../../models/mindbox_remote_message.dart';

class MindboxRemoteMessageCard extends StatelessWidget {
  final MindboxRemoteMessage item;
  final Function(MindboxRemoteMessage) onItemClick;

  const MindboxRemoteMessageCard({
    super.key,
    required this.item,
    required this.onItemClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onItemClick(item),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unique Key: ${item.uniqueKey}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Title: ${item.title}',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Description: ${item.description}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              if (item.imageUrl != null) ...[
                const SizedBox(height: 8.0),
                Image.network(
                  item.imageUrl!,
                  height: 200.0,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ],
              const SizedBox(height: 8.0),
              if (item.pushLink != null)
                Text(
                  'Push Link: ${item.pushLink}',
                  style: const TextStyle(
                    color: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
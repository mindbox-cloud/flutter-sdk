import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_example/assets/MBColors.dart';
import 'package:flutter_example/view/notification_center_page/widgets/mindbox_list_item_card.dart';
import 'package:flutter_example/view_model/view_model.dart';
import 'package:flutter_example/models/mindbox_remote_message.dart';
import 'package:flutter_example/models/payload.dart';
import 'package:flutter_example/view/main_page/widgets/buttons_block/button_nc.dart';
import 'package:flutter_example/view/managers/push_item_manager.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with WidgetsBindingObserver {
  final ItemsManager itemsManager = ItemsManager();
  static const EventChannel eventChannel =
      EventChannel('cloud.mindbox.flutter_example.notifications');
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    itemsManager.loadItemsFromPreferences();

    // Subscription to events from native side
    _subscription = eventChannel.receiveBroadcastStream().listen((event) {
      if (!mounted) return;
      if (event == "newNotification") {
        itemsManager.loadItemsFromPreferences();
      }
    }, onError: (error) {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showCustomToast(context, "Send operation NC.Open");
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      itemsManager.loadItemsFromPreferences();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  // send info about click on push in notification center
  void onItemClick(BuildContext context, MindboxRemoteMessage item) {
    Payload? payload = item.getPayloadObject();
    if (payload != null) {
      ViewModel.asyncOperationNCPushOpen(payload.pushName, payload.pushDate);
    }
    showCustomToast(context, 'Send click on push from notification center');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: MBColors.backgroundColor,
        appBar: AppBar(
          title: const Text('Notification Center'),
          backgroundColor: MBColors.blockBackgroundColor,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<List<MindboxRemoteMessage>>(
                  valueListenable: itemsManager.itemsNotifier,
                  builder: (context, items, child) {
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        int reverseIndex = items.length - 1 - index;
                        return MindboxRemoteMessageCard(
                          item: items[reverseIndex],
                          onItemClick: (item) => onItemClick(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                title: 'Back',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
              CustomButton(
                title: 'Сlear data',
                onPressed: () {
                  itemsManager.clearPreferences();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCustomToast(BuildContext context, String message) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 50.0,
      left: MediaQuery.of(context).size.width * 0.1,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}

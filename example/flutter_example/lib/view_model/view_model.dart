import 'package:mindbox/mindbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewModel {
  static syncOperation() {
    Mindbox.instance.executeSyncOperation(
      operationSystemName: 'APIMethodForReleaseExampleIos',
      operationBody: {
        "viewProduct": {
          "product": {
            "ids": {"website": "1"}
          }
        }
      },
      onSuccess: (data) {},
      onError: (error) {},
    );
  }

  static asyncOperation() {
    Mindbox.instance.executeAsyncOperation(
        operationSystemName: "APIMethodForReleaseExampleIos",
        operationBody: {
          "viewProduct": {
            "product": {
              "ids": {"website": "2"}
            }
          }
        });
  }

  static getSDKVersion(Function complition) {
    Mindbox.instance.nativeSdkVersion.then((value) {
      complition(value);
    });
  }

  static getToken(Function complition) {
    Mindbox.instance.getToken((value) {
      complition(value);
    });
  }

  static getDeviceUUID(Function complition) {
    Mindbox.instance.getDeviceUUID((value) {
      print(value);
      complition(value);
    });
  }

  static chooseInAppCallback(ChooseInappCallback chooseInappCallback) {
    switch (chooseInappCallback) {
      case ChooseInappCallback.defaultInAppCallback:
      case ChooseInappCallback.customInAppCallback:
        Mindbox.instance.registerInAppCallback(callbacks: [
          CustomInAppCallback((id, redirectUrl, payload) {
            print("On click");
            print(id);
            print(redirectUrl);
            print(payload);
          }, (id) {
            print("On close");
            print(id);
          })
        ]);
      case ChooseInappCallback.urlInAppCallback:
        Mindbox.instance.registerInAppCallback(callbacks: [UrlInAppCallback()]);
      case ChooseInappCallback.copyPayloadInAppCallback:
        Mindbox.instance
            .registerInAppCallback(callbacks: [CopyPayloadInAppCallback()]);
      case ChooseInappCallback.emptyInAppCallback:
        Mindbox.instance
            .registerInAppCallback(callbacks: [EmptyInAppCallback()]);
    }
  }

  static onPushClickReceived() {
    Mindbox.instance.onPushClickReceived((link, payload) {
      print(link);
      launchUrl(Uri.parse(link));
    });
  }

  static Future<void> requestPermissions() async {
    Permission.notification.isDenied.then((bool isGranted) async {
      final PermissionStatus status = await Permission.notification.request();

      Mindbox.instance
          .updateNotificationPermissionStatus(granted: status.isGranted);
    });
  }
}

enum ChooseInappCallback {
  defaultInAppCallback,
  customInAppCallback,
  urlInAppCallback,
  emptyInAppCallback,
  copyPayloadInAppCallback,
}

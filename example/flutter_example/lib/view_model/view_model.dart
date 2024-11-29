import 'package:mindbox/mindbox.dart';
import 'package:permission_handler/permission_handler.dart';

class ViewModel {

  //https://developers.mindbox.ru/docs/%D0%BC%D0%B5%D1%82%D0%BE%D0%B4%D1%8B-flutter-sdk
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

  //used for send action "notification center was opened"
  static asyncOperationNCOpen() {
    Mindbox.instance.executeAsyncOperation(
        operationSystemName: "mobileapp.NCOpen",
        operationBody: {}
    );
  }

  //used for send action "click on push from notification center"
  static asyncOperationNCPushOpen(String pushName, String pushDate) {
    Mindbox.instance.executeAsyncOperation(
        operationSystemName: "mobileapp.NCPushOpen",
        operationBody: getPushOpenOperationBody(pushName, pushDate)
    );
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
      complition(value);
    });
  }

  static Future<void> requestPermissions() async {
    Permission.notification.isDenied.then((bool isGranted) async {
      final PermissionStatus status = await Permission.notification.request();

      Mindbox.instance
          .updateNotificationPermissionStatus(granted: status.isGranted);
    });
  }

  //https://developers.mindbox.ru/docs/in-app
  static chooseInAppCallback(ChooseInappCallback chooseInappCallback) {
    switch (chooseInappCallback) {
      case ChooseInappCallback.defaultInAppCallback:
        break;
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

  static Map<String, dynamic> getPushOpenOperationBody(String pushName, String pushDate) {
    return {
      "data": {
        "customerAction": {
          "customFields": {
            "mobPushSendDateTime": pushDate,
            "mobPushTranslateName": pushName
          }
        }
      }
    };
  }
}

enum ChooseInappCallback {
  defaultInAppCallback,
  customInAppCallback,
  urlInAppCallback,
  emptyInAppCallback,
  copyPayloadInAppCallback,
}

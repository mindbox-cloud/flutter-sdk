import 'package:mindbox/mindbox.dart';

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
      complition(value);
    });
  }
}

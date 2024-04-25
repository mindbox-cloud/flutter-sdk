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

  static chooseInAppCallback(ChooseInappCallback chooseInappCallback) {
    switch (chooseInappCallback) {
      case ChooseInappCallback.defaultInAppCallback:
      case ChooseInappCallback.customInAppCallback:
        Mindbox.instance.registerInAppCallback(callbacks: [
          CustomInAppCallback((id, redirectUrl, payload) {}, (id) {})
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
}

enum ChooseInappCallback {
  defaultInAppCallback,
  customInAppCallback,
  urlInAppCallback,
  emptyInAppCallback,
  copyPayloadInAppCallback,
}

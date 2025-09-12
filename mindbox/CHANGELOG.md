## 2.14.1

* Upgrade native Android SDK dependency to v2.14.1.
* Upgrade native iOS SDK dependency to v2.14.1.

## 2.14.0

* Upgrade native Android SDK dependency to v2.14.0.
* Upgrade native iOS SDK dependency to v2.14.0.

## 2.14.0-rc

* Upgrade native Android SDK dependency to v2.14.0-rc.
* Upgrade native iOS SDK dependency to v2.14.0-rc.

## 2.13.4

* Upgrade native Android SDK dependency to v2.13.4.
* Upgrade native iOS SDK dependency to v2.13.4.

## 2.13.2-rc

* Upgrade native Android SDK dependency to v2.13.2-rc.
* Upgrade native iOS SDK dependency to v2.13.2-rc.

## 2.13.1

* Upgrade native Android SDK dependency to v2.13.0.
* Upgrade native iOS SDK dependency to v2.13.1.

## 2.13.0

* Upgrade native Android SDK dependency to v2.13.0.
* Upgrade native iOS SDK dependency to v2.13.0.

## 2.11.0

* Upgrade native Android SDK dependency to v2.11.0.
* Upgrade native iOS SDK dependency to v2.11.0.

## 2.10.2-rc

* Upgrade native Android SDK dependency to v2.10.2-rc.
* Upgrade native iOS SDK dependency to v2.10.3-rc.

## 2.10.1

* Upgrade native Android SDK dependency to v2.10.1.
* Upgrade native iOS SDK dependency to v2.10.2.

## 2.10.0

* Upgrade native Android SDK dependency to v2.10.0.
* Upgrade native iOS SDK dependency to v2.10.1.

## 2.9.1

* Upgrade native Android SDK dependency to v2.9.1.
* Upgrade native iOS SDK dependency to v2.9.0.

## 2.9.0-rc

* Upgrade native Android SDK dependency to v2.9.0-rc.
* Upgrade native iOS SDK dependency to v2.9.0-rc.

## 2.8.5

* Upgrade native iOS SDK dependency to v2.8.6.

## 2.8.4

* Upgrade native Android SDK dependency to v2.8.5.
* Upgrade native iOS SDK dependency to v2.8.4.

## 2.8.3

* Upgrade iOS SDK dependency to v2.8.3.
* Upgrade Android SDK dependency to v2.8.4.
* Added opportunity for turn off automatically request notification permission on start app in iOS
* Added method *updateNotificationPermissionStatus*


## 2.8.2

* Upgrade iOS SDK dependency to v2.8.2.

## 2.8.1
* Upgrade Android SDK dependency to v2.8.2.
* Upgrade iOS SDK dependency to v2.8.1.

## 2.8.0
* Added the capability to display the new in-app Snackbar template and customize the visual appearance of the close button. Customization of templates within the Mindbox interface will be available later.
* Users with this version of the SDK can now participate in A/B testing for the mobile app.
* Added options for handling clicks on in-app messages. See 'Mindbox.instance.registerInAppCallbacks' for more details.
* Updated kotlin-gradle-plugin version.

## 2.6.0
In this version of the SDK, we’ve added the ability to customize the display in-app notifications on the screens of certain categories and products.  
Fixed some problems with the display of in-apps.

## 2.5.0-rc

This version of the SDK includes support for in-app messages. You will now be able to personalize your app by showing users appropriate campaigns based on their actions in the app, on the website, or purchases in retail stores.
You can now launch in-app notifications for users from a certain city, region, or country or exclude the segment of users who should not see the in-app notification.
You can also display in-app notifications when an API is called in your app. Display the message in a specific place in the app or when a user performs a specific action. Learn more in the guide.

Also in this release we added logging of important events in the sdk.

## 2.2.0

* Fix issue when using Firebase onBackgroundMessage handler breaks android part of plugin
* Optimize integration for Android

## 2.1.6

* Upgrade Android SDK dependency to v2.1.10.
* Previously, in some cases on Android the picture in rich-push notifications was not displayed when the phone was turned off. Now we fixed it.

## 2.1.5

* Upgrade Android SDK dependency to v2.1.9.
* Upgrade iOS Mindbox SDK dependency to v2.1.5.

## 2.1.4

* Upgrade Android SDK dependency to v2.1.6.

## 2.1.3

* Upgrade iOS Mindbox SDK dependency to v2.1.2.
* Minor iOS changes on to the CodingKey value for the customAction variable in the OperationBodyRequest class.

## 2.1.2

* Upgrade Android SDK dependency to v2.1.5.
* Upgrade HMS upgraded to 6.5.0.300.
* Fix bug on Android after reinitialization (changing your domain, endpoint and shouldCreateCustomer parameters in existing SDK integration).

## 2.1.1

* Upgrade iOS SDK dependency to v.2.1.1.
* Upgrade Android SDK dependency to v2.1.4.

## 2.1.0

* Upgrade iOS SDK dependency to v.2.1.0.
* Upgrade Android SDK dependency to v2.1.3.
* Update init method: you can change sdk configuration without reinstallation of app.

## 2.0.0

* Upgrade iOS SDK dependency to v2.0.1.
* Upgrade Android SDK dependency to v2.1.2.
* Add support of Huawei Push Kit.
* Update onPushClickReceived method: add second argument with push payload.

## 1.0.2

* Add iOS old format push notifications support.

## 1.0.1

* Change native Mindbox iOS SDK version to 1.3.2.

## 1.0.0

* Stable release of 'mindbox' plugin. Features:
  * receive and show push notification in both mobile platforms.
  * receive push notification data(links) in Flutter.
  * execute sync/async operations.

## 0.2.0

* Add execute async operation.

## 0.1.0

* Initial release.

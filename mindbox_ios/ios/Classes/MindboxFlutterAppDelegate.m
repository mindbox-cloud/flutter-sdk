#import <MindboxFlutterAppDelegate.h>
#import <MindboxIosPlugin.h>

@import Mindbox;

@implementation MindboxFlutterAppDelegateObjc

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // MINDBOX INTEGRATION
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    if ([self shouldRegisterForRemoteNotifications]) {
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound |
                                                 UNAuthorizationOptionAlert |
                                                 UNAuthorizationOptionBadge) completionHandler:^(
                BOOL granted, NSError *_Nullable error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                    [[Mindbox shared] notificationsRequestAuthorizationWithGranted:granted];
                });
            } else {
                NSLog(@"NotificationsRequestAuthorization failed with error: %@",
                      error.localizedDescription);
            }
        }];
    }
    // MINDBOX INTEGRATION
    if (@available(iOS 13.0, *)) {
        [[Mindbox shared] registerBGTasks];
    }
    else {
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    
    // MINDBOX INTEGRATION
    TrackVisitData *data = [[TrackVisitData alloc] init];
    data.launchOptions = launchOptions;
    [[Mindbox shared] trackWithData:data];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
// MINDBOX INTEGRATION
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
}

// MINDBOX INTEGRATION
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"token: %@", deviceToken);
    [[Mindbox shared] apnsTokenUpdateWithDeviceToken:deviceToken];
}

// MINDBOX INTEGRATION
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    TrackVisitData *data = [[TrackVisitData alloc] init];
    data.push = response;
    [[Mindbox shared] trackWithData:data];
    [Mindbox.shared pushClickedWithResponse:response];
    completionHandler();
    [super userNotificationCenter:center didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}

// MINDBOX INTEGRATION
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [[Mindbox shared] application:application performFetchWithCompletionHandler:completionHandler];
}

- (BOOL)shouldRegisterForRemoteNotifications {
    return YES;
}
@end

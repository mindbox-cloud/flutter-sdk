#import <Flutter/Flutter.h>

@interface MindboxIosPlugin : NSObject<FlutterPlugin>

+ (void)pushClicked:(UNNotificationResponse*)response;

@end

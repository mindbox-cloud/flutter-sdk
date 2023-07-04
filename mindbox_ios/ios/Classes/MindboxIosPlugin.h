#import <Flutter/Flutter.h>

@interface MindboxIosPlugin : NSObject<FlutterPlugin>

+ (void)pushClicked:(UNNotificationResponse*)response __attribute__((deprecated));

@end

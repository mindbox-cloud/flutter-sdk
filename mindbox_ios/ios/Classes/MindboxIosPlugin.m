#import "MindboxIosPlugin.h"
#if __has_include(<mindbox_ios/mindbox_ios-Swift.h>)
#import <mindbox_ios/mindbox_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mindbox_ios-Swift.h"
#endif

@implementation MindboxIosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftMindboxIosPlugin registerWithRegistrar:registrar];
}

+ (void)pushClicked:(UNNotificationResponse *)response __attribute__((deprecated(""))) {
}

@end

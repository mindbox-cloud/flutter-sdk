import Flutter
import UIKit
import Mindbox
import MindboxLogger



public class SwiftMindboxIosPlugin: NSObject, FlutterPlugin {
    private final var channel: FlutterMethodChannel
    
    private final let compositeDelegate = CompositeClass()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: Constants.pluginChannelName, binaryMessenger: registrar.messenger())
        let instance = SwiftMindboxIosPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        
    }
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }
    
    @available(*, deprecated)
    @objc
    public static func pushClicked(response: UNNotificationResponse){
    }
    
    
    public func pushClicked(response: UNNotificationResponse){
        let action = response.actionIdentifier as NSString
        let request = response.notification.request
        let userInfo = request.content.userInfo
        
        var link: NSString?
        var payload: NSString?
        
        if let url = userInfo["clickUrl"] as? NSString {
            link = url
        }
        
        if let payloadData = userInfo["payload"] as? NSString {
            payload = payloadData
        }
        
        if(link == nil){
            let aps = userInfo["aps"] as? NSDictionary
            link = aps?["clickUrl"] as? NSString
            payload = aps?["payload"] as? NSString
        }
        
        if let buttons = userInfo["buttons"] as? NSArray {
            buttons.forEach{
                guard
                    let button = $0 as? NSDictionary,
                    let uniqueKey = button["uniqueKey"] as? NSString
                else { return }
                if uniqueKey == action{
                    let btnDictionary = button
                    let url = btnDictionary["url"] as? NSString
                    link = url
                }
            }
        }
        channel.invokeMethod("pushClicked", arguments: [link, payload])
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSdkVersion":
            result(Mindbox.shared.sdkVersion)
        case "init":
            guard let arguments = call.arguments else {
                return
            }
            if let args = arguments as? [String: Any],
               let domain = args["domain"] as? String,
               let endpoint = args["endpointIos"] as? String,
               let previousUuid = args["previousDeviceUUID"] as? String,
               let previousInstallId = args["previousInstallationId"] as? String,
               let subscribeIfCreated = args["subscribeCustomerIfCreated"] as? Bool,
               let shouldCreateCustomer = args["shouldCreateCustomer"] as? Bool{
                let prevUuid = previousUuid.isEmpty ? nil : previousUuid
                let prevId = previousInstallId.isEmpty ? nil : previousInstallId
                do{
                    let config = try MBConfiguration(endpoint: endpoint, domain: domain,previousInstallationId: prevId, previousDeviceUUID: prevUuid, subscribeCustomerIfCreated: subscribeIfCreated, shouldCreateCustomer: shouldCreateCustomer)
                    Mindbox.shared.initialization(configuration: config)
                    result("initialized")
                }catch let error {
                    result(FlutterError(code: "-1", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "-1", message: "Initialization method", details:  "Wrong argument type"))
            }
        case "getDeviceUUID":
            Mindbox.shared.getDeviceUUID {
                deviceUUID in result(deviceUUID)
            }
        case "getTokens":
            Mindbox.shared.getAPNSToken {
                token in result("{\"APNS\":\"\(token)\"}")
            }
        case "getToken":
            Mindbox.shared.getAPNSToken {
                token in result(token)
            }
        case "setLogLevel":
            guard call.arguments is Int else {
                return
            }
            let levelIndex = call.arguments as! Int
            switch (levelIndex) {
            case 0:
                Mindbox.logger.logLevel = .debug
            case 1:
                Mindbox.logger.logLevel = .info
            case 2:
                Mindbox.logger.logLevel = .default
            case 3:
                Mindbox.logger.logLevel = .error
            case 4:
                Mindbox.logger.logLevel = .fault
            default:
                Mindbox.logger.logLevel = .none
            }
            result(0)
        case "executeAsyncOperation":
            let args: [String] = call.arguments as! Array<String>
            Mindbox.shared.executeAsyncOperation(operationSystemName: args[0], json: args[1])
            result("executed")
        case "executeSyncOperation":
            let args: [String] = call.arguments as! Array<String>
            Mindbox.shared.executeSyncOperation(operationSystemName: args[0], json: args[1]) { response in
                switch response {
                case .success(let resultSuccess):
                    result(resultSuccess.createJSON())
                case .failure(let resultError):
                    result(FlutterError(code: "-1", message: resultError.createJSON(), details: nil))
                }
            }
        case "registerInAppCallbacks":
            let args: [String] = call.arguments as! Array<String>
            let callbacks: [InAppMessagesDelegate] = args.compactMap { callback -> InAppMessagesDelegate? in
                switch callback {
                    case "UrlInAppCallback":
                        return URLClass()
                    case "CopyPayloadInAppCallback":
                        return CopyClass()
                    case "EmptyInAppCallback":
                        return EmptyClass()
                    case "CustomInAppCallback":
                        return self
                    default:
                        return nil
                }
            }

            if (callbacks.count > 0) {
                compositeDelegate.delegates = callbacks
                Mindbox.shared.inAppMessagesDelegate = compositeDelegate
                Mindbox.logger.log(level: .info, message: "Use callbacks = \(args)")
            } else {
                Mindbox.logger.log(level: .info, message: "Use default callback")
            }
        case "updateNotificationPermissionStatus":
           guard let granted = call.arguments as? Bool else {
                  return
           }
           Mindbox.shared.notificationsRequestAuthorization(granted: granted)

        case "writeNativeLog":
            guard let args = call.arguments as? [Any], args.count >= 2 else {
                    result(FlutterError(code: "-1", message: "error", details: "Wrong argument count or type"))
                    return
                }
                
            guard let message = args[0] as? String,
                    let levelIndex = args[1] as? Int else {
                    result(FlutterError(code: "-1", message: "error", details: "Wrong argument type"))
                    return
                }
            let logLevel: LogLevel
            
            switch levelIndex {
            case 0:
                logLevel = .debug
            case 1:
                logLevel = .info
            case 2:
                logLevel = .default
            case 3:
                logLevel = .error
            case 4:
                logLevel = .fault
            default:
                logLevel = .none
            }
            Mindbox.logger.log(level: logLevel, message: message)
            result(0)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension SwiftMindboxIosPlugin: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
        pushClicked(response: response)
    }
}

extension SwiftMindboxIosPlugin: InAppMessagesDelegate {
    public func inAppMessageTapAction(id: String, url: URL?, payload: String) {
        channel.invokeMethod("onInAppClick", arguments: [id, url?.absoluteString ?? "", payload])
    }
    
    public func inAppMessageDismissed(id: String) {
        channel.invokeMethod("onInAppDismissed", arguments: id)
    }
}

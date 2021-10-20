import Flutter
import UIKit
import Mindbox

public class SwiftMindboxIosPlugin: NSObject, FlutterPlugin {
    private static var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "mindbox.cloud/flutter-sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftMindboxIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel!)
    }

    @objc
    public static func pushClicked(response: UNNotificationResponse){
        let action = response.actionIdentifier as NSString
        let request = response.notification.request
        let userInfo = request.content.userInfo
        
        var link: NSString?
        
        if let url = userInfo["clickUrl"] as? NSString {
            link = url
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
        channel?.invokeMethod("linkReceived", arguments: link)
    }
    
    @objc
    public static func linkReceived(link: NSString){
        channel?.invokeMethod("linkReceived", arguments: link)
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
        case "getToken":
            Mindbox.shared.getAPNSToken {
                token in result(token)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

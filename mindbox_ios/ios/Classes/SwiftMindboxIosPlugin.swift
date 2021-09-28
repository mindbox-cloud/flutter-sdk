import Flutter
import UIKit
import Mindbox

public class SwiftMindboxIosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mindbox.cloud/flutter-sdk", binaryMessenger: registrar.messenger())
        let instance = SwiftMindboxIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
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
               let previousUuid = args["previousUuid"] as? String,
               let previousInstallId = args["previousInstallId"] as? String,
               let subscribeIfCreated = args["subscribeCustomerIfCreated"] as? Bool,
               let shouldCreateCustomer = args["shouldCreateCustomer"] as? Bool{
                let prevUuid = previousUuid.isEmpty ? nil : previousUuid
                let prevId = previousInstallId.isEmpty ? nil : previousInstallId
                do{
                    let config = try MBConfiguration(endpoint: endpoint, domain: domain,previousInstallationId: prevId, previousDeviceUUID: prevUuid, subscribeCustomerIfCreated: subscribeIfCreated, shouldCreateCustomer: shouldCreateCustomer)
                    Mindbox.shared.initialization(configuration: config)
                }catch let error {
                    result(FlutterError(code: "-1", message: error.localizedDescription, details: nil))
                }
            } else {
                result(FlutterError(code: "-1", message: "iOS could not extract " +
                                        "flutter arguments in method: (init)", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

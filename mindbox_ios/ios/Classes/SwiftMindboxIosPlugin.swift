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
            Mindbox.logger.logLevel = .debug
            Mindbox.logger.log(level: .default, message: "Test log")
            guard let args = call.arguments else {
                return
            }
            if let myArgs = args as? [String: Any],
               let domain = myArgs["domain"] as? String,
               let endpoint = myArgs["endpoint"] as? String {
                do{
                    let config = try MBConfiguration(endpoint: endpoint, domain: domain)
                    Mindbox.shared.initialization(configuration: config)
                }catch let error {
                    print(error.localizedDescription)
                }
                result("\(domain), \(endpoint)")
            } else {
                result(FlutterError(code: "-1", message: "iOS could not extract " +
                                        "flutter arguments in method: (init)", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
}

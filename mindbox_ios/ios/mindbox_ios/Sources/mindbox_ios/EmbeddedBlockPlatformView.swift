import Flutter
import UIKit
@_spi(Internal) import Mindbox
import MindboxLogger

public final class EmbeddedBlockPlatformViewFactory: NSObject, FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger

    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withFrame frame: CGRect,
                       viewIdentifier viewId: Int64,
                       arguments args: Any?) -> FlutterPlatformView {
        EmbeddedBlockPlatformView(viewId: viewId, arguments: args, messenger: messenger)
    }
}

final class EmbeddedBlockPlatformView: NSObject, FlutterPlatformView {

    private let blockView: MindboxEmbeddedBlockView
    private let channel: FlutterMethodChannel

    private var appearance = Keys.placeholder
    private var outcome: String?

    init(viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
        let params = arguments as? [String: Any]
        let placeSystemName = params?[Keys.placeSystemName] as? String ?? ""
        let height = (params?[Keys.height] as? NSNumber)?.doubleValue ?? 0
        let timeout = (params?[Keys.timeoutMs] as? NSNumber).map { TimeInterval($0.doubleValue) / 1000 }

        blockView = MindboxEmbeddedBlockView(placeSystemName: placeSystemName,
                                            height: CGFloat(height),
                                            timeout: timeout)
        channel = FlutterMethodChannel(name: "\(Constants.embeddedBlockViewType)/\(viewId)",
                                       binaryMessenger: messenger)
        super.init()

        if placeSystemName.isEmpty {
            Logger.common(message: "[EmbeddedBlock] A Flutter block was created without a place system name and has nothing to resolve",
                          level: .error,
                          category: .embeddedBlocks)
        }

        syncStandIns(hasPlaceholder: params?[Keys.hasPlaceholder] as? Bool ?? false,
                     hasErrorView: params?[Keys.hasErrorView] as? Bool ?? false)

        blockView.delegate = self
        blockView.setAppearanceObserver { [weak self] appearance in
            self?.report(appearance: appearance)
        }
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    deinit {
        blockView.release()
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        blockView
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Keys.sync:
            send()
            result(nil)
        case Keys.setHostVisible:
            guard let isHostVisible = call.arguments as? Bool else {
                result(FlutterError(code: "bad_arguments",
                                    message: "setHostVisible expects a boolean",
                                    details: nil))
                return
            }

            blockView.setHostVisible(isHostVisible)
            result(nil)
        case Keys.setStandIns:
            guard let arguments = call.arguments as? [String: Any],
                  let hasPlaceholder = arguments[Keys.hasPlaceholder] as? Bool,
                  let hasErrorView = arguments[Keys.hasErrorView] as? Bool else {
                result(FlutterError(code: "bad_arguments",
                                    message: "setStandIns expects hasPlaceholder and hasErrorView booleans",
                                    details: nil))
                return
            }

            syncStandIns(hasPlaceholder: hasPlaceholder, hasErrorView: hasErrorView)
            result(nil)
        case Keys.release:
            blockView.release()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func syncStandIns(hasPlaceholder: Bool, hasErrorView: Bool) {
        if hasPlaceholder {
            if blockView.placeholderView == nil {
                blockView.placeholderView = Self.makeStandIn()
            }
        } else {
            blockView.placeholderView = nil
        }

        if hasErrorView {
            if blockView.errorView == nil {
                blockView.errorView = Self.makeStandIn()
            }
        } else {
            blockView.errorView = nil
        }
    }

    private static func makeStandIn() -> UIView {
        let standIn = UIView()
        standIn.backgroundColor = .clear
        standIn.isUserInteractionEnabled = false
        return standIn
    }

    private func report(appearance: MindboxEmbeddedBlockAppearance) {
        self.appearance = Keys.name(of: appearance)
        send()
    }

    private func report(outcome: String) {
        self.outcome = outcome
        send()
    }

    private func send() {
        var arguments: [String: Any] = [Keys.appearance: appearance]
        if let outcome = outcome {
            arguments[Keys.outcome] = outcome
        }

        channel.invokeMethod(Keys.report, arguments: arguments)
    }

    private enum Keys {
        static let placeSystemName = "placeSystemName"
        static let height = "height"
        static let timeoutMs = "timeoutMs"
        static let hasPlaceholder = "hasPlaceholder"
        static let hasErrorView = "hasErrorView"
        static let report = "report"
        static let sync = "sync"
        static let setHostVisible = "setHostVisible"
        static let setStandIns = "setStandIns"
        static let release = "release"
        static let appearance = "appearance"
        static let outcome = "outcome"
        static let load = "load"
        static let fail = "fail"
        static let placeholder = "placeholder"
        static let content = "content"
        static let error = "error"
        static let collapsed = "collapsed"

        static func name(of appearance: MindboxEmbeddedBlockAppearance) -> String {
            switch appearance {
            case .placeholder: return placeholder
            case .content: return content
            case .error: return error
            case .collapsed: return collapsed
            }
        }
    }
}

// MARK: - MindboxEmbeddedBlockViewDelegate

extension EmbeddedBlockPlatformView: MindboxEmbeddedBlockViewDelegate {

    func mindboxEmbeddedBlockViewDidLoad(_ blockView: MindboxEmbeddedBlockView) {
        report(outcome: Keys.load)
    }

    func mindboxEmbeddedBlockViewDidFail(_ blockView: MindboxEmbeddedBlockView) {
        report(outcome: Keys.fail)
    }
}

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

/// The channel shared by every block, asked before any of them exists: the look a block of a place
/// starts with. Dart decides `placeholder` and `hidden` on its own; `automatic` depends on the SDK's
/// memory of the place, and only this side has it.
enum EmbeddedBlockPluginChannel {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: EmbeddedBlockWire.pluginChannel,
                                           binaryMessenger: registrar.messenger())
        channel.setMethodCallHandler(handle)
    }

    static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case EmbeddedBlockWire.initialAppearance:
            let arguments = call.arguments as? [String: Any]
            guard let placeSystemName = arguments?[EmbeddedBlockWire.placeSystemName] as? String,
                  let loadingStrategy = EmbeddedBlockWire.loadingStrategy(
                    of: arguments?[EmbeddedBlockWire.loadingStrategy] as? String) else {
                result(FlutterError(code: EmbeddedBlockWire.badArguments,
                                    message: "initialAppearance expects placeSystemName and loadingStrategy words",
                                    details: nil))
                return
            }

            let appearance = MindboxEmbeddedBlockView.initialAppearance(placeSystemName: placeSystemName,
                                                                         loadingStrategy: loadingStrategy)
            result(EmbeddedBlockWire.name(of: appearance))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

final class EmbeddedBlockPlatformView: NSObject, FlutterPlatformView {

    private let blockView: MindboxEmbeddedBlockView
    private let channel: FlutterMethodChannel

    private var appearance = EmbeddedBlockWire.placeholder
    private var outcome: String?
    private var failReason: String?

    /// The report being sent is the animated reveal of the content — set for that one send only.
    private var isRevealAnimated = false

    init(viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
        let params = arguments as? [String: Any]
        let placeSystemName = params?[EmbeddedBlockWire.placeSystemName] as? String ?? ""
        let height = (params?[EmbeddedBlockWire.height] as? NSNumber)?.doubleValue ?? 0
        let timeout = (params?[EmbeddedBlockWire.timeoutMs] as? NSNumber).map { TimeInterval($0.doubleValue) / 1000 }
        let loadingStrategyWord = params?[EmbeddedBlockWire.loadingStrategy] as? String
        let loadingStrategy = EmbeddedBlockWire.loadingStrategy(of: loadingStrategyWord)
        let animatesReveal = params?[EmbeddedBlockWire.animatesReveal] as? Bool ?? true

        blockView = MindboxEmbeddedBlockView(placeSystemName: placeSystemName,
                                            height: CGFloat(height),
                                            loadingStrategy: loadingStrategy ?? .automatic,
                                            timeout: timeout,
                                            animatesReveal: animatesReveal)
        channel = FlutterMethodChannel(name: "\(EmbeddedBlockWire.viewType)/\(viewId)",
                                       binaryMessenger: messenger)
        super.init()

        if placeSystemName.isEmpty {
            Logger.common(message: "[EmbeddedBlock] A Flutter block was created without a place system name and has nothing to resolve",
                          level: .error,
                          category: .embeddedBlocks)
        }
        if let loadingStrategyWord, loadingStrategy == nil {
            Logger.common(message: "[EmbeddedBlock] A Flutter block '\(placeSystemName)' was created with a loading strategy this SDK does not know ('\(loadingStrategyWord)') and starts as automatic",
                          level: .error,
                          category: .embeddedBlocks)
        }

        syncStandIns(hasPlaceholder: params?[EmbeddedBlockWire.hasPlaceholder] as? Bool ?? false,
                     hasErrorView: params?[EmbeddedBlockWire.hasErrorView] as? Bool ?? false)

        blockView.delegate = self
        // Whether the change deserves the reveal animation is the view's decision, read while the
        // observer runs; the wrapper's own frame is what it animates, so it is told rather than asked.
        blockView.setAppearanceObserver { [weak self] appearance in
            guard let self else { return }
            self.report(appearance: appearance, isRevealAnimated: self.blockView.isRevealAnimated)
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
        case EmbeddedBlockWire.sync:
            send()
            result(nil)
        case EmbeddedBlockWire.setHostVisible:
            guard let isHostVisible = call.arguments as? Bool else {
                result(FlutterError(code: EmbeddedBlockWire.badArguments,
                                    message: "setHostVisible expects a boolean",
                                    details: nil))
                return
            }

            blockView.setHostVisible(isHostVisible)
            result(nil)
        case EmbeddedBlockWire.setStandIns:
            guard let arguments = call.arguments as? [String: Any],
                  let hasPlaceholder = arguments[EmbeddedBlockWire.hasPlaceholder] as? Bool,
                  let hasErrorView = arguments[EmbeddedBlockWire.hasErrorView] as? Bool else {
                result(FlutterError(code: EmbeddedBlockWire.badArguments,
                                    message: "setStandIns expects hasPlaceholder and hasErrorView booleans",
                                    details: nil))
                return
            }

            syncStandIns(hasPlaceholder: hasPlaceholder, hasErrorView: hasErrorView)
            result(nil)
        case EmbeddedBlockWire.release:
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

    private func report(appearance: MindboxEmbeddedBlockAppearance, isRevealAnimated: Bool) {
        self.appearance = EmbeddedBlockWire.name(of: appearance)
        self.isRevealAnimated = isRevealAnimated
        send()
        self.isRevealAnimated = false
    }

    private func report(outcome: String, reason: String? = nil) {
        self.outcome = outcome
        self.failReason = reason
        send()
    }

    private func send() {
        var arguments: [String: Any] = [EmbeddedBlockWire.appearance: appearance]
        if let outcome = outcome {
            arguments[EmbeddedBlockWire.outcome] = outcome
        }
        if let failReason = failReason {
            arguments[EmbeddedBlockWire.reason] = failReason
        }
        if isRevealAnimated {
            arguments[EmbeddedBlockWire.animated] = true
            arguments[EmbeddedBlockWire.revealDurationMs] =
                Int((MindboxEmbeddedBlockView.revealAnimationDuration * 1000).rounded())
        }

        channel.invokeMethod(EmbeddedBlockWire.report, arguments: arguments)
    }
}

// MARK: - MindboxEmbeddedBlockViewDelegate

extension EmbeddedBlockPlatformView: MindboxEmbeddedBlockViewDelegate {

    func mindboxEmbeddedBlockViewDidLoad(_ blockView: MindboxEmbeddedBlockView) {
        report(outcome: EmbeddedBlockWire.load)
    }

    func mindboxEmbeddedBlockViewDidBecomeEmpty(_ blockView: MindboxEmbeddedBlockView) {
        report(outcome: EmbeddedBlockWire.empty)
    }

    func mindboxEmbeddedBlockViewDidFail(_ blockView: MindboxEmbeddedBlockView,
                                         reason: MindboxEmbeddedBlockFailReason) {
        report(outcome: EmbeddedBlockWire.fail, reason: reason.rawValue)
    }
}

// MARK: - The words both sides of the channels agree on

enum EmbeddedBlockWire {
    static let viewType = Constants.embeddedBlockViewType
    static let pluginChannel = "\(Constants.embeddedBlockViewType)/plugin"

    static let placeSystemName = "placeSystemName"
    static let height = "height"
    static let timeoutMs = "timeoutMs"
    static let loadingStrategy = "loadingStrategy"
    static let animatesReveal = "animatesReveal"
    static let hasPlaceholder = "hasPlaceholder"
    static let hasErrorView = "hasErrorView"
    static let appearance = "appearance"
    static let outcome = "outcome"
    static let reason = "reason"
    static let animated = "animated"
    static let revealDurationMs = "revealDurationMs"

    static let report = "report"
    static let sync = "sync"
    static let setHostVisible = "setHostVisible"
    static let setStandIns = "setStandIns"
    static let release = "release"
    static let initialAppearance = "initialAppearance"
    static let badArguments = "bad_arguments"

    static let load = "load"
    static let empty = "empty"
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

    /// The strategy behind its word — the same three words on every platform — or `nil` for a word
    /// this version does not know.
    static func loadingStrategy(of word: String?) -> MindboxEmbeddedBlockLoadingStrategy? {
        switch word {
        case "automatic": return .automatic
        case "placeholder": return .placeholder
        case "hidden": return .hidden
        default: return nil
        }
    }
}

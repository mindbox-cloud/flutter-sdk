import Flutter
import UIKit
@_spi(Internal) import Mindbox
import MindboxLogger

/// Builds the native embedded block for a Flutter platform view.
///
/// The block itself is the SDK's `MindboxEmbeddedBlockView`, whole and unchanged: the resolver, the
/// waiting budget, the page and its bridge stay on the native side, and Flutter gets a view to place
/// plus two signals to react to. A Dart implementation over a WebView plugin would have to reproduce
/// all of that and then keep up with it release after release.
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

/// One block on a Flutter screen: the native container plus the channel it reports through.
final class EmbeddedBlockPlatformView: NSObject, FlutterPlatformView {

    private let blockView: MindboxEmbeddedBlockView
    private let channel: FlutterMethodChannel

    /// The last pair sent up. Kept because the two signals arrive separately while Dart needs them
    /// together: the visibility observer fires inside the container's state change, the outcome on
    /// the next turn of the main queue — so each message carries the whole picture, not a delta.
    private var isVisible = true
    private var outcome: String?

    init(viewId: Int64, arguments: Any?, messenger: FlutterBinaryMessenger) {
        let params = arguments as? [String: Any]
        let placeSystemName = params?[Keys.placeSystemName] as? String ?? ""
        let height = (params?[Keys.height] as? NSNumber)?.doubleValue ?? 0

        blockView = MindboxEmbeddedBlockView(placeSystemName: placeSystemName,
                                            height: CGFloat(height))
        channel = FlutterMethodChannel(name: "\(Constants.embeddedBlockViewType)/\(viewId)",
                                       binaryMessenger: messenger)
        super.init()

        if placeSystemName.isEmpty {
            Logger.common(message: "[EmbeddedBlock] A Flutter block was created without a place system name and has nothing to resolve",
                          level: .error,
                          category: .embeddedBlocks)
        }

        blockView.delegate = self
        blockView.setVisibilityObserver { [weak self] isVisible in
            self?.report(isVisible: isVisible)
        }
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
    }

    deinit {
        // The platform view is gone, so the block's screen is gone with it. Waiting for the last
        // reference to go instead would keep a page loading for a screen nobody can see.
        blockView.release()
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        blockView
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Keys.setHostVisible:
            guard let isHostVisible = call.arguments as? Bool else {
                result(FlutterError(code: "bad_arguments",
                                    message: "setHostVisible expects a boolean",
                                    details: nil))
                return
            }

            blockView.setHostVisible(isHostVisible)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func report(isVisible: Bool) {
        self.isVisible = isVisible
        send()
    }

    private func report(outcome: String) {
        self.outcome = outcome
        send()
    }

    private func send() {
        // No outcome key while there is no outcome: a nil inside the dictionary would have to survive
        // the standard codec, and "the key is absent" says the same thing without relying on that.
        var arguments: [String: Any] = [Keys.isVisible: isVisible]
        if let outcome = outcome {
            arguments[Keys.outcome] = outcome
        }

        channel.invokeMethod(Keys.report, arguments: arguments)
    }

    private enum Keys {
        static let placeSystemName = "placeSystemName"
        static let height = "height"
        static let report = "report"
        static let setHostVisible = "setHostVisible"
        static let isVisible = "isVisible"
        static let outcome = "outcome"
        static let load = "load"
        static let fail = "fail"
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

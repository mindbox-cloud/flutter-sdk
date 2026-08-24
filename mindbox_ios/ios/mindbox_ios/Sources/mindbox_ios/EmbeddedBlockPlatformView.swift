import Flutter
import UIKit
@_spi(Internal) import Mindbox
import MindboxLogger

/// Builds the native embedded block for a Flutter platform view.
///
/// The block itself is the SDK's `MindboxEmbeddedBlockView`, whole and unchanged: the resolver, the
/// waiting budget, the page and its bridge stay on the native side, and Flutter gets a view to place
/// plus the signals to react to. A Dart implementation over a WebView plugin would have to reproduce
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
    /// together: the appearance observer fires inside the container's state change, the outcome on
    /// the next turn of the main queue — so each message carries the whole picture, not a delta.
    private var appearance = Keys.placeholder
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
        // The platform view is gone, so the block's screen is gone with it. Waiting for the last
        // reference to go instead would keep a page loading for a screen nobody can see.
        //
        // `release()` and nothing else: it marks the block released before dropping the delegate and
        // the observer itself. Dropping the delegate here first would do it while the block still
        // counts as live, and its `didSet` would read the change as a new subscriber and schedule a
        // delivery on the main queue for a view being torn down.
        blockView.release()
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        blockView
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case Keys.sync:
            // Dart has its handler up now and asks where the block stands. Everything reported before
            // this point went to a channel nobody was listening on yet.
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Puts an empty view where the host draws its own screen — the same arrangement the SwiftUI
    /// wrapper uses.
    ///
    /// A Flutter widget cannot become a `UIView`, so the container is not given the screen: it is
    /// given the fact that the place is taken. That is all it needs — a placeholder of its own is
    /// held back, and a failed block keeps its height instead of collapsing. What is actually drawn
    /// in that space is a widget, laid out by Flutter over the platform view.
    private func syncStandIns(hasPlaceholder: Bool, hasErrorView: Bool) {
        // Assigned only on a change: the container swaps its shown layer on every new view, and
        // a fresh stand-in on every Dart rebuild would swap it for an identical one.
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
        // The stand-in is a placeholder for space, not for touches: what the host drew over it is a
        // widget, and it is Flutter that has to hear the taps on it.
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
        // No outcome key while there is no outcome: a nil inside the dictionary would have to survive
        // the standard codec, and "the key is absent" says the same thing without relying on that.
        var arguments: [String: Any] = [Keys.appearance: appearance]
        if let outcome = outcome {
            arguments[Keys.outcome] = outcome
        }

        channel.invokeMethod(Keys.report, arguments: arguments)
    }

    private enum Keys {
        static let placeSystemName = "placeSystemName"
        static let height = "height"
        static let hasPlaceholder = "hasPlaceholder"
        static let hasErrorView = "hasErrorView"
        static let report = "report"
        static let sync = "sync"
        static let setHostVisible = "setHostVisible"
        static let setStandIns = "setStandIns"
        static let appearance = "appearance"
        static let outcome = "outcome"
        static let load = "load"
        static let fail = "fail"
        static let placeholder = "placeholder"
        static let content = "content"
        static let error = "error"
        static let collapsed = "collapsed"

        /// Spelled out rather than derived from the case name: the wire word is a contract with the
        /// Dart side, and renaming a case in the SDK must not quietly change it.
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

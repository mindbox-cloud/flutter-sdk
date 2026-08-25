package cloud.mindbox.mindbox_android

import android.content.Context
import android.graphics.Color
import android.view.View
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.annotations.InternalMindboxApi
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockAppearance
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockListener
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockView
import cloud.mindbox.mobile_sdk.logger.Level
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Builds the native embedded block for a Flutter platform view.
 *
 * The block itself is the SDK's `MindboxEmbeddedBlockView`, whole and unchanged: the content
 * factory, the waiting budget, the page and its bridge stay on the native side, and Flutter gets a
 * view to place plus the signals to react to. A Dart implementation over a WebView plugin would have
 * to reproduce all of that and then keep up with it release after release.
 */
@OptIn(InternalMindboxApi::class)
internal class EmbeddedBlockPlatformViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        EmbeddedBlockPlatformView(context, viewId, args, messenger)
}

/** One block on a Flutter screen: the native container plus the channel it reports through. */
@OptIn(InternalMindboxApi::class)
internal class EmbeddedBlockPlatformView(
    private val context: Context,
    viewId: Int,
    arguments: Any?,
    messenger: BinaryMessenger,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val blockView: MindboxEmbeddedBlockView
    private val channel: MethodChannel

    /**
     * The last pair sent up. Kept because the two signals arrive separately while Dart needs them
     * together: the appearance observer fires inside the container's state change, the outcome on the
     * next turn of the main looper — so each message carries the whole picture, not a delta.
     */
    private var appearance = PLACEHOLDER
    private var outcome: String? = null

    /**
     * The stand-ins currently handed to the container, kept to tell "the host still draws its own
     * screen" from "it has just started to". Declared above `init`, which sets them: a property
     * initializer further down the class would run afterwards and put the null back.
     */
    private var placeholderStandIn: View? = null
    private var errorStandIn: View? = null

    init {
        val params = arguments as? Map<*, *>
        val placeSystemName = params?.get(KEY_PLACE_SYSTEM_NAME) as? String ?: ""

        // Absent means the host named no budget, and that is exactly the container's own `null`: the
        // SDK default. Read as a Number rather than an Int: the standard codec sends a value that
        // fits in 32 bits as an Int and a longer one as a Long, and a budget in milliseconds sits
        // right where the two meet.
        val timeoutMs = (params?.get(KEY_TIMEOUT_MS) as? Number)?.toLong()

        // The height is not passed on: on Android the block is a frame sized by its parent, and here
        // that parent is Flutter — the platform view is laid out to the height Dart gives it.
        blockView = MindboxEmbeddedBlockView(context, placeSystemName, timeoutMs)
        channel = MethodChannel(messenger, "$VIEW_TYPE/$viewId")

        // Said here rather than left to the container: it does warn about a place it cannot resolve,
        // but in the words of the XML attribute it was written for, which names nothing a Flutter
        // host can set. The same mistake is reported the same way on both platforms.
        if (placeSystemName.isEmpty()) {
            Mindbox.writeLog(
                message = "[EmbeddedBlock] A Flutter block was created without a place system name " +
                    "and has nothing to resolve",
                logLevel = Level.ERROR,
            )
        }

        syncStandIns(
            hasPlaceholder = params?.get(KEY_HAS_PLACEHOLDER) as? Boolean ?: false,
            hasErrorView = params?.get(KEY_HAS_ERROR_VIEW) as? Boolean ?: false,
        )

        channel.setMethodCallHandler(this)
        blockView.setListener(
            object : MindboxEmbeddedBlockListener {
                override fun onLoad(view: MindboxEmbeddedBlockView) = report(outcome = LOAD)

                override fun onFail(view: MindboxEmbeddedBlockView) = report(outcome = FAIL)
            },
        )
        // Last, and after the handler is in place: subscribing hands out the current appearance right
        // away, and an empty place answers synchronously while the block attaches.
        blockView.setAppearanceObserver { appearance -> report(appearance) }
    }

    override fun getView(): View = blockView

    override fun dispose() {
        // The platform view is gone, so the block's screen is gone with it. Waiting for the host
        // Activity to be destroyed instead would keep a page loading for a screen nobody can see.
        blockView.setAppearanceObserver(null)
        blockView.setListener(null)
        blockView.release()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SYNC -> {
                // Dart has its handler up now and asks where the block stands. Everything reported
                // before this point went to a channel nobody was listening on yet.
                send()
                result.success(null)
            }
            METHOD_SET_HOST_VISIBLE -> {
                val isHostVisible = call.arguments as? Boolean
                if (isHostVisible == null) {
                    result.error(ERROR_BAD_ARGUMENTS, "setHostVisible expects a boolean", null)
                    return
                }
                blockView.setHostVisible(isHostVisible)
                result.success(null)
            }
            METHOD_SET_STAND_INS -> {
                val arguments = call.arguments as? Map<*, *>
                val hasPlaceholder = arguments?.get(KEY_HAS_PLACEHOLDER) as? Boolean
                val hasErrorView = arguments?.get(KEY_HAS_ERROR_VIEW) as? Boolean
                if (hasPlaceholder == null || hasErrorView == null) {
                    result.error(
                        ERROR_BAD_ARGUMENTS,
                        "setStandIns expects hasPlaceholder and hasErrorView booleans",
                        null,
                    )
                    return
                }
                syncStandIns(hasPlaceholder = hasPlaceholder, hasErrorView = hasErrorView)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /**
     * Puts an empty view where the host draws its own screen — the same arrangement the Compose
     * wrapper uses for a slot it cannot hand over directly.
     *
     * A Flutter widget cannot become an Android View, so the container is not given the screen: it is
     * given the fact that the place is taken. That is all it needs — a placeholder of its own is held
     * back, and a failed block keeps its height instead of collapsing. What is actually drawn in that
     * space is a widget, laid out by Flutter over the platform view.
     */
    private fun syncStandIns(hasPlaceholder: Boolean, hasErrorView: Boolean) {
        // Assigned only on a change: the container swaps its shown layer on every new view, and a
        // fresh stand-in on every Dart rebuild would swap it for an identical one.
        if (hasPlaceholder) {
            if (placeholderStandIn == null) {
                placeholderStandIn = makeStandIn()
                blockView.setPlaceholderView(placeholderStandIn)
            }
        } else if (placeholderStandIn != null) {
            placeholderStandIn = null
            blockView.setPlaceholderView(null)
        }

        if (hasErrorView) {
            if (errorStandIn == null) {
                errorStandIn = makeStandIn()
                blockView.setErrorView(errorStandIn)
            }
        } else if (errorStandIn != null) {
            errorStandIn = null
            blockView.setErrorView(null)
        }
    }

    private fun makeStandIn(): View = View(context).apply {
        setBackgroundColor(Color.TRANSPARENT)
        // The stand-in is a placeholder for space, not for touches: what the host drew over it is a
        // widget, and it is Flutter that has to hear the taps on it.
        isClickable = false
        isFocusable = false
    }

    private fun report(appearance: MindboxEmbeddedBlockAppearance) {
        this.appearance = nameOf(appearance)
        send()
    }

    private fun report(outcome: String) {
        this.outcome = outcome
        send()
    }

    private fun send() {
        // No outcome key while there is no outcome: a null inside the map would have to survive the
        // standard codec, and "the key is absent" says the same thing without relying on that.
        val arguments = mutableMapOf<String, Any>(KEY_APPEARANCE to appearance)
        outcome?.let { arguments[KEY_OUTCOME] = it }
        channel.invokeMethod(METHOD_REPORT, arguments)
    }

    private companion object {

        const val VIEW_TYPE = EMBEDDED_BLOCK_VIEW_TYPE
        const val KEY_PLACE_SYSTEM_NAME = "placeSystemName"
        const val KEY_TIMEOUT_MS = "timeoutMs"
        const val KEY_HAS_PLACEHOLDER = "hasPlaceholder"
        const val KEY_HAS_ERROR_VIEW = "hasErrorView"
        const val KEY_APPEARANCE = "appearance"
        const val KEY_OUTCOME = "outcome"
        const val METHOD_REPORT = "report"
        const val METHOD_SYNC = "sync"
        const val METHOD_SET_HOST_VISIBLE = "setHostVisible"
        const val METHOD_SET_STAND_INS = "setStandIns"
        const val ERROR_BAD_ARGUMENTS = "bad_arguments"
        const val LOAD = "load"
        const val FAIL = "fail"
        const val PLACEHOLDER = "placeholder"
        const val CONTENT = "content"
        const val ERROR = "error"
        const val COLLAPSED = "collapsed"

        /**
         * Spelled out rather than taken from the enum name: the wire word is a contract with the Dart
         * side, and renaming a case in the SDK must not quietly change it.
         */
        fun nameOf(appearance: MindboxEmbeddedBlockAppearance): String = when (appearance) {
            MindboxEmbeddedBlockAppearance.PLACEHOLDER -> PLACEHOLDER
            MindboxEmbeddedBlockAppearance.CONTENT -> CONTENT
            MindboxEmbeddedBlockAppearance.ERROR -> ERROR
            MindboxEmbeddedBlockAppearance.COLLAPSED -> COLLAPSED
        }
    }
}

/** The type both native factories register the block under — must match the Dart constant. */
internal const val EMBEDDED_BLOCK_VIEW_TYPE = "mindbox.cloud/flutter-sdk/embedded_block"

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

@OptIn(InternalMindboxApi::class)
internal class EmbeddedBlockPlatformViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        EmbeddedBlockPlatformView(context, viewId, args, messenger)
}

@OptIn(InternalMindboxApi::class)
internal class EmbeddedBlockPlatformView(
    private val context: Context,
    viewId: Int,
    arguments: Any?,
    messenger: BinaryMessenger,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val blockView: MindboxEmbeddedBlockView
    private val channel: MethodChannel

    private var appearance = PLACEHOLDER
    private var outcome: String? = null

    private var placeholderStandIn: View? = null
    private var errorStandIn: View? = null

    init {
        val params = arguments as? Map<*, *>
        val placeSystemName = params?.get(KEY_PLACE_SYSTEM_NAME) as? String ?: ""

        val timeoutMs = (params?.get(KEY_TIMEOUT_MS) as? Number)?.toLong()

        blockView = MindboxEmbeddedBlockView(context, placeSystemName, timeoutMs)
        channel = MethodChannel(messenger, "$VIEW_TYPE/$viewId")

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
        blockView.setAppearanceObserver { appearance -> report(appearance) }
    }

    override fun getView(): View = blockView

    override fun dispose() {
        blockView.setAppearanceObserver(null)
        blockView.setListener(null)
        blockView.release()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_SYNC -> {
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
            METHOD_RELEASE -> {
                blockView.release()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun syncStandIns(hasPlaceholder: Boolean, hasErrorView: Boolean) {
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
        const val METHOD_RELEASE = "release"
        const val ERROR_BAD_ARGUMENTS = "bad_arguments"
        const val LOAD = "load"
        const val FAIL = "fail"
        const val PLACEHOLDER = "placeholder"
        const val CONTENT = "content"
        const val ERROR = "error"
        const val COLLAPSED = "collapsed"

        fun nameOf(appearance: MindboxEmbeddedBlockAppearance): String = when (appearance) {
            MindboxEmbeddedBlockAppearance.PLACEHOLDER -> PLACEHOLDER
            MindboxEmbeddedBlockAppearance.CONTENT -> CONTENT
            MindboxEmbeddedBlockAppearance.ERROR -> ERROR
            MindboxEmbeddedBlockAppearance.COLLAPSED -> COLLAPSED
        }
    }
}

internal const val EMBEDDED_BLOCK_VIEW_TYPE = "mindbox.cloud/flutter-sdk/embedded_block"

package cloud.mindbox.mindbox_android

import android.content.Context
import android.graphics.Color
import android.view.View
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.annotations.InternalMindboxApi
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockAppearance
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockFailReason
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockListener
import cloud.mindbox.mobile_sdk.embedded.MindboxEmbeddedBlockLoadingStrategy
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

/**
 * The channel shared by every block, asked before any of them exists: the look a block of a place
 * starts with. Dart decides `placeholder` and `hidden` on its own; `automatic` depends on the SDK's
 * memory of the place, and only this side has it.
 */
@OptIn(InternalMindboxApi::class)
internal class EmbeddedBlockPluginChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, EmbeddedBlockWire.PLUGIN_CHANNEL)

    fun attach() {
        channel.setMethodCallHandler(this)
    }

    fun detach() {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            EmbeddedBlockWire.METHOD_INITIAL_APPEARANCE -> {
                val arguments = call.arguments as? Map<*, *>
                val placeSystemName = arguments?.get(EmbeddedBlockWire.KEY_PLACE_SYSTEM_NAME) as? String
                val loadingStrategy = EmbeddedBlockWire.loadingStrategyOf(
                    arguments?.get(EmbeddedBlockWire.KEY_LOADING_STRATEGY) as? String,
                )
                if (placeSystemName == null || loadingStrategy == null) {
                    result.error(
                        EmbeddedBlockWire.ERROR_BAD_ARGUMENTS,
                        "initialAppearance expects placeSystemName and loadingStrategy words",
                        null,
                    )
                    return
                }
                val appearance = MindboxEmbeddedBlockView.initialAppearance(
                    context = context,
                    placeSystemName = placeSystemName,
                    loadingStrategy = loadingStrategy,
                )
                result.success(EmbeddedBlockWire.nameOf(appearance))
            }
            else -> result.notImplemented()
        }
    }
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

    private var appearance = EmbeddedBlockWire.PLACEHOLDER
    private var outcome: String? = null
    private var failReason: String? = null

    /** The report being sent is the animated reveal of the content — set for that one send only. */
    private var isRevealAnimated = false

    private var placeholderStandIn: View? = null
    private var errorStandIn: View? = null

    init {
        val params = arguments as? Map<*, *>
        val placeSystemName = params?.get(EmbeddedBlockWire.KEY_PLACE_SYSTEM_NAME) as? String ?: ""

        val timeoutMs = (params?.get(EmbeddedBlockWire.KEY_TIMEOUT_MS) as? Number)?.toLong()
        val loadingStrategyWord = params?.get(EmbeddedBlockWire.KEY_LOADING_STRATEGY) as? String
        val loadingStrategy = EmbeddedBlockWire.loadingStrategyOf(loadingStrategyWord)
        val animatesReveal = params?.get(EmbeddedBlockWire.KEY_ANIMATES_REVEAL) as? Boolean ?: true

        blockView = MindboxEmbeddedBlockView(
            context = context,
            placeSystemName = placeSystemName,
            timeoutMs = timeoutMs,
            loadingStrategy = loadingStrategy ?: MindboxEmbeddedBlockLoadingStrategy.AUTOMATIC,
            animatesReveal = animatesReveal,
        )
        channel = MethodChannel(messenger, "${EmbeddedBlockWire.VIEW_TYPE}/$viewId")

        if (placeSystemName.isEmpty()) {
            Mindbox.writeLog(
                message = "[EmbeddedBlock] A Flutter block was created without a place system name " +
                    "and has nothing to resolve",
                logLevel = Level.ERROR,
            )
        }
        if (loadingStrategyWord != null && loadingStrategy == null) {
            Mindbox.writeLog(
                message = "[EmbeddedBlock] A Flutter block '$placeSystemName' was created with a loading " +
                    "strategy this SDK does not know ('$loadingStrategyWord') and starts as automatic",
                logLevel = Level.ERROR,
            )
        }

        syncStandIns(
            hasPlaceholder = params?.get(EmbeddedBlockWire.KEY_HAS_PLACEHOLDER) as? Boolean ?: false,
            hasErrorView = params?.get(EmbeddedBlockWire.KEY_HAS_ERROR_VIEW) as? Boolean ?: false,
        )

        channel.setMethodCallHandler(this)
        blockView.setListener(
            object : MindboxEmbeddedBlockListener {
                override fun onLoad(view: MindboxEmbeddedBlockView) = report(outcome = EmbeddedBlockWire.LOAD)

                override fun onEmpty(view: MindboxEmbeddedBlockView) = report(outcome = EmbeddedBlockWire.EMPTY)

                override fun onFail(view: MindboxEmbeddedBlockView, reason: MindboxEmbeddedBlockFailReason) =
                    report(outcome = EmbeddedBlockWire.FAIL, reason = reason.value)
            },
        )
        // Whether the change deserves the reveal animation is the view's decision, read while the
        // observer runs; the wrapper's own frame is what it animates, so it is told rather than asked.
        blockView.setAppearanceObserver { appearance ->
            report(appearance, isRevealAnimated = blockView.isRevealAnimated)
        }
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
            EmbeddedBlockWire.METHOD_SYNC -> {
                send()
                result.success(null)
            }
            EmbeddedBlockWire.METHOD_SET_HOST_VISIBLE -> {
                val isHostVisible = call.arguments as? Boolean
                if (isHostVisible == null) {
                    result.error(EmbeddedBlockWire.ERROR_BAD_ARGUMENTS, "setHostVisible expects a boolean", null)
                    return
                }
                blockView.setHostVisible(isHostVisible)
                result.success(null)
            }
            EmbeddedBlockWire.METHOD_SET_STAND_INS -> {
                val arguments = call.arguments as? Map<*, *>
                val hasPlaceholder = arguments?.get(EmbeddedBlockWire.KEY_HAS_PLACEHOLDER) as? Boolean
                val hasErrorView = arguments?.get(EmbeddedBlockWire.KEY_HAS_ERROR_VIEW) as? Boolean
                if (hasPlaceholder == null || hasErrorView == null) {
                    result.error(
                        EmbeddedBlockWire.ERROR_BAD_ARGUMENTS,
                        "setStandIns expects hasPlaceholder and hasErrorView booleans",
                        null,
                    )
                    return
                }
                syncStandIns(hasPlaceholder = hasPlaceholder, hasErrorView = hasErrorView)
                result.success(null)
            }
            EmbeddedBlockWire.METHOD_RELEASE -> {
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

    private fun report(appearance: MindboxEmbeddedBlockAppearance, isRevealAnimated: Boolean) {
        this.appearance = EmbeddedBlockWire.nameOf(appearance)
        this.isRevealAnimated = isRevealAnimated
        send()
        this.isRevealAnimated = false
    }

    private fun report(outcome: String, reason: String? = null) {
        this.outcome = outcome
        this.failReason = reason
        send()
    }

    private fun send() {
        val arguments = mutableMapOf<String, Any>(EmbeddedBlockWire.KEY_APPEARANCE to appearance)
        outcome?.let { arguments[EmbeddedBlockWire.KEY_OUTCOME] = it }
        failReason?.let { arguments[EmbeddedBlockWire.KEY_REASON] = it }
        if (isRevealAnimated) {
            arguments[EmbeddedBlockWire.KEY_ANIMATED] = true
            arguments[EmbeddedBlockWire.KEY_REVEAL_DURATION_MS] =
                MindboxEmbeddedBlockView.REVEAL_ANIMATION_DURATION_MS
        }
        channel.invokeMethod(EmbeddedBlockWire.METHOD_REPORT, arguments)
    }
}

internal const val EMBEDDED_BLOCK_VIEW_TYPE = "mindbox.cloud/flutter-sdk/embedded_block"

/** The words both sides of the channels agree on, and the translations between them and the SDK. */
@OptIn(InternalMindboxApi::class)
internal object EmbeddedBlockWire {
    const val VIEW_TYPE = EMBEDDED_BLOCK_VIEW_TYPE
    const val PLUGIN_CHANNEL = "$VIEW_TYPE/plugin"

    const val KEY_PLACE_SYSTEM_NAME = "placeSystemName"
    const val KEY_TIMEOUT_MS = "timeoutMs"
    const val KEY_LOADING_STRATEGY = "loadingStrategy"
    const val KEY_ANIMATES_REVEAL = "animatesReveal"
    const val KEY_HAS_PLACEHOLDER = "hasPlaceholder"
    const val KEY_HAS_ERROR_VIEW = "hasErrorView"
    const val KEY_APPEARANCE = "appearance"
    const val KEY_OUTCOME = "outcome"
    const val KEY_REASON = "reason"
    const val KEY_ANIMATED = "animated"
    const val KEY_REVEAL_DURATION_MS = "revealDurationMs"

    const val METHOD_REPORT = "report"
    const val METHOD_SYNC = "sync"
    const val METHOD_SET_HOST_VISIBLE = "setHostVisible"
    const val METHOD_SET_STAND_INS = "setStandIns"
    const val METHOD_RELEASE = "release"
    const val METHOD_INITIAL_APPEARANCE = "initialAppearance"
    const val ERROR_BAD_ARGUMENTS = "bad_arguments"

    const val LOAD = "load"
    const val EMPTY = "empty"
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

    /**
     * The strategy behind its word — the same three words on every platform — or `null` for a
     * word this version does not know.
     */
    fun loadingStrategyOf(word: String?): MindboxEmbeddedBlockLoadingStrategy? = when (word) {
        "automatic" -> MindboxEmbeddedBlockLoadingStrategy.AUTOMATIC
        "placeholder" -> MindboxEmbeddedBlockLoadingStrategy.PLACEHOLDER
        "hidden" -> MindboxEmbeddedBlockLoadingStrategy.HIDDEN
        else -> null
    }
}

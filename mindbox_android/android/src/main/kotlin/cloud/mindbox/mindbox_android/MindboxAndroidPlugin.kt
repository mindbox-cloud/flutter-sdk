package cloud.mindbox.mindbox_android

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.MindboxConfiguration
import cloud.mindbox.mobile_sdk.inapp.presentation.InAppCallback
import cloud.mindbox.mobile_sdk.inapp.presentation.callbacks.*
import cloud.mindbox.mobile_sdk.logger.Level
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener

/** MindboxAndroidPlugin */
class MindboxAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, NewIntentListener {
    private lateinit var context: Activity
    private var binding: ActivityPluginBinding? = null
    private var deviceUuidSubscription: String? = null
    private var tokenSubscription: String? = null
    private lateinit var channel: MethodChannel

    inner class InAppCallbackImpl : InAppCallback {
        override fun onInAppClick(id: String, redirectUrl: String, payload: String) {
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod("onInAppClick", listOf(id, redirectUrl, payload))
            }
        }

        override fun onInAppDismissed(id: String) {
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod("onInAppDismissed", id)
            }
        }
    }

    companion object {
        @Deprecated(
            "Push clicks are processed inside the library now. This method will be removed in future release." +
                    " Please abort changes you make following points 3.3 and 5 of Mindbox API intructions",
            level = DeprecationLevel.WARNING
        )
        fun pushClicked(link: String, payload: String) {
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Mindbox.writeLog("On ATTACHED ENGINE", Level.INFO)
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mindbox.cloud/flutter-sdk")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getSdkVersion" -> {
                result.success(Mindbox.getSdkVersion())
            }
            "init" -> {
                if (call.arguments is HashMap<*, *>) {
                    val args = call.arguments as HashMap<*, *>
                    val domain: String = args["domain"] as String
                    val endpointId: String = args["endpointAndroid"] as String
                    val previousDeviceUuid: String = args["previousDeviceUUID"] as String
                    val previousInstallId: String = args["previousInstallationId"] as String
                    val subscribeIfCreated: Boolean = args["subscribeCustomerIfCreated"] as Boolean
                    val shouldCreateCustomer: Boolean = args["shouldCreateCustomer"] as Boolean
                    val config = MindboxConfiguration.Builder(context.applicationContext, domain, endpointId)
                        .setPreviousDeviceUuid(previousDeviceUuid)
                        .setPreviousInstallationId(previousInstallId)
                        .subscribeCustomerIfCreated(subscribeIfCreated)
                        .shouldCreateCustomer(shouldCreateCustomer)
                        .build()
                    Mindbox.init(activity = context, config, listOf())
                    result.success("initialized")
                } else {
                    result.error("-1", "Initialization error", "Wrong argument type")
                }
            }
            "getDeviceUUID" -> {
                if (deviceUuidSubscription != null) {
                    Mindbox.disposeDeviceUuidSubscription(deviceUuidSubscription!!)
                }
                deviceUuidSubscription = Mindbox.subscribeDeviceUuid { uuid ->
                    result.success(uuid)
                }
            }
            "getToken" -> {
                if (tokenSubscription != null) {
                    Mindbox.disposePushTokenSubscription(tokenSubscription!!)
                }
                tokenSubscription = Mindbox.subscribePushToken { token ->
                    result.success(token)
                }
            }
            "executeAsyncOperation" -> {
                if (call.arguments is List<*>) {
                    val args = call.arguments as List<*>
                    Mindbox.executeAsyncOperation(context.applicationContext, args[0] as String, args[1] as String)
                    result.success("executed")
                }
            }
            "executeSyncOperation" -> {
                if (call.arguments is List<*>) {
                    val args = call.arguments as List<*>
                    Mindbox.executeSyncOperation(
                        context.applicationContext,
                        args[0] as String,
                        args[1] as String,
                        { response ->
                            result.success(response)
                        },
                        { error ->
                            result.error(
                                error.statusCode.toString(),
                                error.toJson(),
                                null
                            )
                        })
                }
            }
            "setLogLevel" -> {
                if (call.arguments is Int) {
                    val logIndex: Int = call.arguments as Int
                    val logLevel : Level = Level.values()[logIndex]
                    Mindbox.setLogLevel(logLevel)
                    result.success(0)
                } else {
                     result.error("-1", "Initialization error", "Wrong argument type")
                }
            }
            "registerInAppCallbacks" -> {
                if (call.arguments is List<*>) {
                    val args = call.arguments as List<*>
                    val callbacks = args.filterIsInstance<String>()
                        .mapNotNull { type ->
                            when (type) {
                                "UrlInAppCallback" -> UrlInAppCallback()
                                "EmptyInAppCallback" -> EmptyInAppCallback()
                                "CopyPayloadInAppCallback" -> CopyPayloadInAppCallback()
                                "CustomInAppCallback" -> InAppCallbackImpl()
                                else -> null
                            }
                        }
                    if (callbacks.isNotEmpty()) {
                        Mindbox.registerInAppCallback(ComposableInAppCallback(callbacks))
                    }
                }
            }
            "updateNotificationPermissionStatus" -> {
                Mindbox.updateNotificationPermissionStatus(context = context)
            }

            "writeNativeLog" -> {
                if (call.arguments is List<*>) {
                    val args = call.arguments as List<*>
                    if (args.size < 2) {
                        result.error("-1", "error", "Wrong argument count")
                    }
                    try {
                        val message: String? = args[0] as String
                        val logIndex: Int = args[1] as Int
                        val logLevel: Level = Level.values()[logIndex]
                        Mindbox.writeLog(message!!, logLevel)
                        result.success(0)
                    }
                    catch (e: Exception)
                    {
                        result.error("-1", "error", "Exception occurred: ${e.message}")
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = binding.activity
        this.binding = binding
        binding.addOnNewIntentListener(this)
        handleIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        binding?.removeOnNewIntentListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        this.binding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        binding?.removeOnNewIntentListener(this)
    }

    private fun handleIntent(intent: Intent) {
        intent.let {
            val uniqueKey = intent.getStringExtra("uniq_push_key")
            if (uniqueKey != null) {
                Mindbox.onPushClicked(context.applicationContext, it)
                Mindbox.onNewIntent(intent)
                val link = Mindbox.getUrlFromPushIntent(intent) ?: ""
                val payload = Mindbox.getPayloadFromPushIntent(intent) ?: ""
                Handler(Looper.getMainLooper()).post {
                    channel.invokeMethod("pushClicked", listOf(link, payload))
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false
    }
}
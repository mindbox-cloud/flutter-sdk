package cloud.mindbox.mindbox_android

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.MindboxConfiguration
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
    private lateinit var context: Context
    private var binding: ActivityPluginBinding? = null
    private var deviceUuidSubscription: String? = null
    private var tokenSubscription: String? = null
    lateinit var channel: MethodChannel

    companion object {
        @Deprecated(
            "Push clicks are processed inside the library now. This method will be removed in future release." +
                    " Please abort changes you make following points 3.3 and 5 of Mindbox API intructions",
            level = DeprecationLevel.WARNING
        )
        fun pushClicked(link: String, payload: String) {
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mindbox.cloud/flutter-sdk")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
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
                    val config = MindboxConfiguration.Builder(context, domain, endpointId)
                        .setPreviousDeviceUuid(previousDeviceUuid)
                        .setPreviousInstallationId(previousInstallId)
                        .subscribeCustomerIfCreated(subscribeIfCreated)
                        .shouldCreateCustomer(shouldCreateCustomer)
                        .build()
                    Mindbox.init(context, config, listOf())
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
                    Mindbox.executeAsyncOperation(context, args[0] as String, args[1] as String)
                    result.success("executed")
                }
            }
            "executeSyncOperation" -> {
                if (call.arguments is List<*>) {
                    val args = call.arguments as List<*>
                    Mindbox.executeSyncOperation(
                        context,
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
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
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
                Mindbox.onPushClicked(context, it)
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
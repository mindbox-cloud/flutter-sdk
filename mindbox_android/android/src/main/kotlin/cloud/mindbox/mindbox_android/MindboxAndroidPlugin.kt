package cloud.mindbox.mindbox_android

import android.content.Context
import android.os.Handler
import android.os.Looper

import androidx.annotation.NonNull
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.MindboxConfiguration
import io.flutter.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** MindboxAndroidPlugin */
class MindboxAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var context: Context

    companion object {
        lateinit var channel: MethodChannel

        fun pushClicked(url: String) {
            Handler(Looper.getMainLooper()).post {
                channel.invokeMethod("linkReceived", url)
            }
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
                    try {
                        // Android SDK validation doesn't work
                        Mindbox.init(context, config)
                        result.success("initialized")
                    } catch (e: Exception) {
                        result.error("-1", e.message, e.localizedMessage)
                    }
                } else {
                    result.error("-1", "Initialization error", "Wrong argument type")
                }
            }
            "getDeviceUUID" -> {
                Mindbox.subscribeDeviceUuid { uuid ->
                    result.success(uuid)
                }
            }
            "getToken" -> {
                Mindbox.subscribeFmsToken { token ->
                    result.success(token)
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
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.i("MindboxAndroidPlugin", "Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.i("MindboxAndroidPlugin", "Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        Log.i("MindboxAndroidPlugin", "Not yet implemented")
    }
}
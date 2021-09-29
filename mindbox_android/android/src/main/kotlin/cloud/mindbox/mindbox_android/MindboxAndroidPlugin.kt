package cloud.mindbox.mindbox_android

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import cloud.mindbox.mobile_sdk.InitializeMindboxException
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mobile_sdk.MindboxConfiguration
import cloud.mindbox.mobile_sdk.logger.Level

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/** MindboxAndroidPlugin */
class MindboxAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

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
            "updateToken" -> {
                if (call.arguments is String) {
                    val token = call.arguments as String
                    try {
                        Mindbox.updateFmsToken(context, token)
                        result.success("token updated")
                    } catch (e: Exception) {
                        result.error("-1", e.message, e.localizedMessage)
                    }
                } else {
                    result.error("-1", "Token updating error", "Wrong argument type")
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
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }
}
package cloud.mindbox.flutter_example

import android.app.Application
import android.content.Context
import android.util.Log
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mindbox_firebase.MindboxFirebase
import cloud.mindbox.mindbox_huawei.MindboxHuawei
import cloud.mindbox.mobile_sdk.pushes.MindboxRemoteMessage
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class MainApplication : Application() {

    var events: EventChannel.EventSink? = null
    private val gson = Gson()
    override fun onCreate() {
        super.onCreate()
        Mindbox.initPushServices(applicationContext, listOf(MindboxFirebase, MindboxHuawei))
    }

    fun setupEventChannel(flutterEngine: FlutterEngine) {
        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "cloud.mindbox.flutter_example.notifications"
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                this@MainApplication.events = events
            }

            override fun onCancel(arguments: Any?) {
                this@MainApplication.events = null
            }
        })
    }

    fun notifyFlutterNewData() {
        Handler(Looper.getMainLooper()).post {
            events?.success("newNotification")
        }
    }

    // We use sharedPreference to save push data for example purposes only. Don't use this solution for yourself
    fun saveNotification(message: MindboxRemoteMessage) {
        val sharedPreferences =
            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val editor = sharedPreferences.edit()
        val notificationsJson = sharedPreferences.getString("flutter.notifications", "[]")
        val type = object : TypeToken<MutableList<String>>() {}.type
        val notifications: MutableList<String> = gson.fromJson(notificationsJson, type)
        notifications.add(gson.toJson(message))
        editor.putString("flutter.notifications", gson.toJson(notifications))
        editor.commit()
        notifyFlutterNewData()
    }
}

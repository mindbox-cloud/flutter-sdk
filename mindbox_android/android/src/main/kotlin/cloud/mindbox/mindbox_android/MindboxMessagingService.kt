package cloud.mindbox.mindbox_android

import android.util.Log
import cloud.mindbox.mobile_sdk.Mindbox
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONObject
//
//class Response(json: String) : JSONObject(json) {
//    val type: String? = this.optString("type")
//    val data = this.optJSONArray("data")
//        ?.let { 0.until(it.length()).map { i -> it.optJSONObject(i) } } // returns an array of JSONObject
//        ?.map { Foo(it.toString()) } // transforms each JSONObject of the array into Foo
//}
//
//class Foo(json: String) : JSONObject(json) {
//    val id = this.optInt("id")
//    val title: String? = this.optString("title")
//}

class MindboxMessagingService: FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        Mindbox.updateFmsToken(applicationContext, token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.i("Mindbox push", remoteMessage.data.toString())

        Mindbox.onPushReceived(applicationContext, remoteMessage.data["uniqueKey"]!!)

        Mindbox.handleRemoteMessage(
            context = applicationContext,
            message = remoteMessage,
            channelId = "mindbox_c",
            channelName = "Mindbox channel",
            pushSmallIcon = android.R.drawable.ic_dialog_info,
            channelDescription = "Descr"
        )

        super.onMessageReceived(remoteMessage)
    }
}
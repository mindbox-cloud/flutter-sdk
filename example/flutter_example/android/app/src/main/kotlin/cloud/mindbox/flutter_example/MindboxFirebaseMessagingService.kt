package cloud.mindbox.flutter_example

import cloud.mindbox.mobile_sdk.Mindbox
import com.google.firebase.messaging.*
import cloud.mindbox.mindbox_firebase.MindboxFirebase
import android.util.Log
import com.google.firebase.messaging.RemoteMessage

class MindboxFirebaseMessagingService: FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        Mindbox.updatePushToken(applicationContext, token, MindboxFirebase)
        super.onNewToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        val channelId = "default_channel_id"
        val channelName = "default_channel_name"
        val channelDescription = "default_channel_description"
        val pushSmallIcon = android.R.drawable.ic_dialog_info


        val messageWasHandled = Mindbox.handleRemoteMessage(
            context = applicationContext,
            message = remoteMessage,
            activities = mapOf(),
            channelId = channelId,
            channelName = channelName,
            pushSmallIcon = pushSmallIcon,
            defaultActivity = MainActivity::class.java,
            channelDescription = channelDescription
        )
        val isMindboxPush = MindboxFirebase.isMindboxPush(remoteMessage = remoteMessage)

        // Method for getting info from Mindbox push
        val mindboxMessage = MindboxFirebase.convertToMindboxRemoteMessage(remoteMessage = remoteMessage)
        // If you want to save the notification you can call your save function from here.
        mindboxMessage?.let {
            val app = applicationContext as MainApplication
            app.saveNotification(it)
        }
        if (!messageWasHandled) {
            //If the push notification was not from Mindbox or it contains incorrect data, then you can write a fallback to process it
        }
    }

}
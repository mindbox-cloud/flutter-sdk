package cloud.mindbox.flutter_example

import android.app.Notification
import android.graphics.Color
import cloud.mindbox.mobile_sdk.Mindbox
import com.google.firebase.messaging.*
import cloud.mindbox.mindbox_firebase.MindboxFirebase
import android.util.Log
import androidx.core.app.NotificationCompat
import cloud.mindbox.mobile_sdk.pushes.MindboxRemoteMessage
import com.google.firebase.messaging.RemoteMessage
import androidx.core.graphics.toColorInt

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
        val pushSmallIcon = R.mipmap.ic_notification

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
            showCustomPush(channelId, mindboxMessage)
            val app = applicationContext as MainApplication
            app.saveNotification(mindboxMessage)
        }
        if (!messageWasHandled) {
            //If the push notification was not from Mindbox or it contains incorrect data, then you can write a fallback to process it
        }
    }

    fun showCustomPush(channelId: String, mindboxMessage: MindboxRemoteMessage) {
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(mindboxMessage.title)
            .setContentText(mindboxMessage.description)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setColor("#00E9FF".toColorInt()) // Example color, replace with your desired color
            .setColorized(true)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(mindboxMessage.description))
            .build()

        // Show the notification
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.notify(mindboxMessage.uniqueKey.hashCode(), notification)
    }

}
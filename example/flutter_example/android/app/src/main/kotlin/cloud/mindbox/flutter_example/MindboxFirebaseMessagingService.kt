package cloud.mindbox.flutter_example

import cloud.mindbox.mobile_sdk.Mindbox
import com.google.firebase.messaging.*
import cloud.mindbox.mindbox_firebase.MindboxFirebase

class MindboxFirebaseMessagingService: FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        Mindbox.updatePushToken(applicationContext, token, MindboxFirebase)
        super.onNewToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        val channelId = "test"
        val channelName = "test"
        val channelDescription = "test"
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

        if (!messageWasHandled) {
        }
    }

}
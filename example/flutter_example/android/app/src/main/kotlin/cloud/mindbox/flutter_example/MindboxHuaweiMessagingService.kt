package cloud.mindbox.flutter_example

import cloud.mindbox.mobile_sdk.Mindbox
import com.huawei.hms.push.*
import cloud.mindbox.mindbox_huawei.MindboxHuawei

class MindboxHuaweiMessagingService: HmsMessageService() {
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Mindbox.updatePushToken(applicationContext, token, MindboxHuawei)
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

        if (!messageWasHandled) {
            //If the push notification was not from Mindbox or it contains incorrect data, then you can write a fallback to process it
        }

    }
}
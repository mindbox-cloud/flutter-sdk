package cloud.mindbox.flutter_example

import android.app.Application
import cloud.mindbox.mobile_sdk.Mindbox
import cloud.mindbox.mindbox_firebase.MindboxFirebase
import cloud.mindbox.mindbox_huawei.MindboxHuawei

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Mindbox.initPushServices(applicationContext, listOf(MindboxFirebase, MindboxHuawei))
    }
}
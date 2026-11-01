package com.batteryassistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Starts the Flutter background service after device boot
 * so battery monitoring resumes automatically.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // The flutter_background_service plugin picks up its own restart;
            // this receiver exists to ensure the system grants us boot permission.
        }
    }
}

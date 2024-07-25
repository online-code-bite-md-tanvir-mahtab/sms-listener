package com.example.testmessage

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    companion object {
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent != null && Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent.action) {
            for (sms in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
                val sender = sms.displayOriginatingAddress ?: "Unknown"
                val message = sms.displayMessageBody ?: "No message"
                val smsData = mapOf("sender" to sender, "message" to message)
                methodChannel?.invokeMethod("receivedSms", smsData)
            }
        }
    }
}

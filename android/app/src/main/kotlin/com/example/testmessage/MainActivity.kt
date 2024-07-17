package com.example.testmessage

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.Telephony

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sms.receiver.channel"
    private val REQUEST_CODE = 1
    private lateinit var smsReceiver: BroadcastReceiver

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "receive_sms") {
                if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) != PackageManager.PERMISSION_GRANTED) {
                    ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECEIVE_SMS), REQUEST_CODE)
                } else {
                    registerSmsReceiver(result)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun registerSmsReceiver(result: MethodChannel.Result) {
        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent != null && Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent.action) {
                    for (sms in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
                        val sender = sms.displayOriginatingAddress ?: "Unknown"
                        val message = sms.displayMessageBody ?: "No message"
                        val smsData = mapOf("sender" to sender, "message" to message)
                        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("receivedSms", smsData)
                    }
                }
            }
        }
        registerReceiver(smsReceiver, IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION))
        result.success(null)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(smsReceiver)
    }
}

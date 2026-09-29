package com.voxguard.app

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class VoxCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = callDetails.handle?.schemeSpecificPart ?: ""
        val callerName = callDetails.callerDisplayName ?: "Unknown Caller"

        // Send interception event to Flutter engine via MainActivity channel
        MainActivity.screeningChannel?.invokeMethod("onCallIntercepted", mapOf(
            "phoneNumber" to phoneNumber,
            "callerName" to callerName
        ))

        // Default response: Allow phone call while AI screening overlay engages
        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()

        respondToCall(callDetails, response)
    }

    companion object {
        fun buildBlockResponse(): CallResponse {
            return CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(true)
                .build()
        }
    }
}

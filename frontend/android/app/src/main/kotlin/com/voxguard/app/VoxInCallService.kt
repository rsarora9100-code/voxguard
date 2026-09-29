package com.voxguard.app

import android.telecom.Call
import android.telecom.InCallService

class VoxInCallService : InCallService() {

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        val handle = call.details.handle?.schemeSpecificPart ?: ""
        
        call.registerCallback(object : Call.Callback() {
            override fun onStateChanged(call: Call, state: Int) {
                super.onStateChanged(call, state)
            }
        })
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
    }
}

package com.voxguard.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import androidx.core.app.NotificationCompat

class CallOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var params: WindowManager.LayoutParams? = null

    companion object {
        const val ACTION_SHOW = "ACTION_SHOW"
        const val ACTION_UPDATE = "ACTION_UPDATE"
        const val ACTION_HIDE = "ACTION_HIDE"
        private const val CHANNEL_ID = "voxguard_overlay_channel"
        private const val NOTIF_ID = 2024
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIF_ID, createNotification("VoxGuard Call Security Active"))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> {
                val phone = intent.getStringExtra("phoneNumber") ?: ""
                val name = intent.getStringExtra("callerName") ?: ""
                val level = intent.getStringExtra("riskLevel") ?: "LOW"
                val score = intent.getDoubleExtra("riskScore", 0.0)
                val colorCode = intent.getStringExtra("colorCode") ?: "#10B981"
                showFloatingOverlay(phone, name, level, score, colorCode)
            }
            ACTION_UPDATE -> {
                val level = intent.getStringExtra("riskLevel") ?: "LOW"
                val score = intent.getDoubleExtra("riskScore", 0.0)
                val colorCode = intent.getStringExtra("colorCode") ?: "#10B981"
                val transcript = intent.getStringExtra("latestTranscript")
                val isDeepfake = intent.getBooleanExtra("isDeepfake", false)
                updateFloatingOverlay(level, score, colorCode, transcript, isDeepfake)
            }
            ACTION_HIDE -> {
                removeFloatingOverlay()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun showFloatingOverlay(phone: String, name: String, level: String, score: Double, colorCode: String) {
        if (overlayView != null) return

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.layout_call_overlay, null)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = 180
        }

        updateViews(phone, name, level, score, colorCode, null, false)
        setupDragTouchListener()

        windowManager?.addView(overlayView, params)
    }

    private fun updateFloatingOverlay(level: String, score: Double, colorCode: String, transcript: String?, isDeepfake: Boolean) {
        if (overlayView == null) return
        updateViews(null, null, level, score, colorCode, transcript, isDeepfake)
    }

    private fun updateViews(phone: String?, name: String?, level: String, score: Double, colorCode: String, transcript: String?, isDeepfake: Boolean) {
        overlayView?.let { view ->
            val txtName = view.findViewById<TextView>(R.id.txtCallerName)
            val txtScore = view.findViewById<TextView>(R.id.txtRiskScore)
            val txtLevel = view.findViewById<TextView>(R.id.txtRiskLevel)
            val txtTranscript = view.findViewById<TextView>(R.id.txtTranscript)
            val badgeContainer = view.findViewById<View>(R.id.riskBadgeContainer)
            val iconDeepfake = view.findViewById<ImageView>(R.id.iconDeepfake)

            if (name != null) txtName.text = name
            txtScore.text = "${score.toInt()}%"
            txtLevel.text = if (isDeepfake) "DEEPFAKE DETECTED" else "$level RISK"

            val parsedColor = try { Color.parseColor(colorCode) } catch (e: Exception) { Color.GREEN }
            txtScore.setTextColor(parsedColor)
            txtLevel.setTextColor(parsedColor)
            badgeContainer.setBackgroundColor(Color.argb(40, Color.red(parsedColor), Color.green(parsedColor), Color.blue(parsedColor)))

            if (isDeepfake) {
                iconDeepfake.visibility = View.VISIBLE
            } else {
                iconDeepfake.visibility = View.GONE
            }

            if (!transcript.isNullOrEmpty()) {
                txtTranscript.visibility = View.VISIBLE
                txtTranscript.text = transcript
            }
        }
    }

    private fun setupDragTouchListener() {
        overlayView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                if (event == null || params == null) return false
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params!!.x
                        initialY = params!!.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params!!.x = initialX + (event.rawX - initialTouchX).toInt()
                        params!!.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager?.updateViewLayout(overlayView, params)
                        return true
                    }
                }
                return false
            }
        })
    }

    private fun removeFloatingOverlay() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VoxGuard Call Security",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(contentText: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("VoxGuard AI Shield")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        removeFloatingOverlay()
        super.onDestroy()
    }
}

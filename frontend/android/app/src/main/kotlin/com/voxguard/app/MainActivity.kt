package com.voxguard.app

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREENING_CHANNEL = "com.voxguard.app/call_screening"
    private val OVERLAY_CHANNEL = "com.voxguard.app/call_overlay"
    private val REQUEST_SCREENING_ROLE = 1001

    companion object {
        var screeningChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Call Screening Channel
        screeningChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREENING_CHANNEL)
        screeningChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                            if (!roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                                startActivityForResult(intent, REQUEST_SCREENING_ROLE)
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.error("UNAVAILABLE", "Call screening role not available", null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "isScreeningRoleHeld" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        result.success(roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING))
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Call Overlay Channel (SYSTEM_ALERT_WINDOW)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "showOverlay" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    val name = call.argument<String>("callerName") ?: ""
                    val riskLevel = call.argument<String>("riskLevel") ?: "LOW"
                    val riskScore = call.argument<Double>("riskScore") ?: 0.0
                    val colorCode = call.argument<String>("colorCode") ?: "#10B981"

                    val intent = Intent(this, CallOverlayService::class.java).apply {
                        action = CallOverlayService.ACTION_SHOW
                        putExtra("phoneNumber", phone)
                        putExtra("callerName", name)
                        putExtra("riskLevel", riskLevel)
                        putExtra("riskScore", riskScore)
                        putExtra("colorCode", colorCode)
                    }
                    startService(intent)
                    result.success(true)
                }
                "updateOverlay" -> {
                    val riskLevel = call.argument<String>("riskLevel") ?: "LOW"
                    val riskScore = call.argument<Double>("riskScore") ?: 0.0
                    val colorCode = call.argument<String>("colorCode") ?: "#10B981"
                    val transcript = call.argument<String>("latestTranscript")
                    val isDeepfake = call.argument<Boolean>("isDeepfake") ?: false

                    val intent = Intent(this, CallOverlayService::class.java).apply {
                        action = CallOverlayService.ACTION_UPDATE
                        putExtra("riskLevel", riskLevel)
                        putExtra("riskScore", riskScore)
                        putExtra("colorCode", colorCode)
                        putExtra("latestTranscript", transcript)
                        putExtra("isDeepfake", isDeepfake)
                    }
                    startService(intent)
                    result.success(true)
                }
                "closeOverlay" -> {
                    val intent = Intent(this, CallOverlayService::class.java).apply {
                        action = CallOverlayService.ACTION_HIDE
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}

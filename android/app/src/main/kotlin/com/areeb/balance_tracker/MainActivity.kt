package com.areeb.balance_tracker

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.areeb.tally/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Lock window to 60 FPS on startup to eliminate touch-boost jitter and guarantee frame budget
        try {
            @Suppress("DEPRECATION")
            val currentDisplay = if (Build.VERSION.SDK_INT >= 30) display else windowManager.defaultDisplay
            val mode = currentDisplay?.mode
            val mode60 = currentDisplay?.supportedModes?.firstOrNull {
                mode != null && it.physicalWidth == mode.physicalWidth && it.physicalHeight == mode.physicalHeight &&
                kotlin.math.abs(it.refreshRate - 60f) < 1.0f
            }
            val attrs = window.attributes
            if (mode60 != null) {
                attrs.preferredDisplayModeId = mode60.modeId
                attrs.preferredRefreshRate = mode60.refreshRate
            } else {
                attrs.preferredRefreshRate = 60f
            }
            if (Build.VERSION.SDK_INT >= 35) {
                attrs.setFrameRateBoostOnTouchEnabled(false)
            }
            window.attributes = attrs
        } catch (_: Exception) {}

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.areeb.tally/display_rate").setMethodCallHandler { call, result ->
            if (call.method != "setPreference") {
                result.notImplemented()
            } else {
                val requested = call.argument<Int>("hz") ?: 60
                if (requested !in listOf(0, 60, 120)) {
                    result.error("INVALID_ARGUMENT", "Use System, 60 or 120 Hz", null)
                } else {
                    @Suppress("DEPRECATION")
                    val currentDisplay = if (Build.VERSION.SDK_INT >= 30) display else windowManager.defaultDisplay
                    val mode = currentDisplay?.mode
                    val modes = currentDisplay?.supportedModes?.filter {
                        mode != null && it.physicalWidth == mode.physicalWidth && it.physicalHeight == mode.physicalHeight
                    } ?: emptyList()
                    val rates = modes.map { it.refreshRate }
                    val selected = modes.minByOrNull { kotlin.math.abs(it.refreshRate - requested.toFloat()) }
                    val accepted = requested == 0 || (selected != null && kotlin.math.abs(selected.refreshRate - requested) < 1.0f)
                    val attributes = window.attributes
                    attributes.preferredDisplayModeId = if (requested == 0 || !accepted) 0 else selected!!.modeId
                    attributes.preferredRefreshRate = if (requested == 0 || !accepted) 0f else selected!!.refreshRate
                    if (Build.VERSION.SDK_INT >= 35) {
                        attributes.setFrameRateBoostOnTouchEnabled(requested == 0)
                    }
                    window.attributes = attributes
                    result.success(mapOf("accepted" to accepted,
                        "supported" to rates.map { kotlin.math.round(it).toInt() }.distinct(),
                        "reportedHz" to (currentDisplay?.refreshRate ?: 0f)))
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setAppIcon" -> {
                    val iconName = call.argument<String>("iconName")
                    if (iconName != null) {
                        val success = changeAppIcon(iconName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "iconName cannot be null", null)
                    }
                }
                "getCurrentIcon" -> {
                    result.success(getCurrentIcon())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun changeAppIcon(targetIcon: String): Boolean {
        return try {
            val pkg = packageName
            val pm = packageManager
            val aliases = listOf("Ledger", "Paper", "Ink")

            for (alias in aliases) {
                val comp = ComponentName(pkg, "$pkg.MainActivity$alias")
                val state = if (alias.equals(targetIcon, ignoreCase = true)) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }
                pm.setComponentEnabledSetting(comp, state, PackageManager.DONT_KILL_APP)
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getCurrentIcon(): String {
        return try {
            val pkg = packageName
            val pm = packageManager
            val aliases = listOf("Ledger", "Paper", "Ink")
            for (alias in aliases) {
                val comp = ComponentName(pkg, "$pkg.MainActivity$alias")
                val state = pm.getComponentEnabledSetting(comp)
                if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                    return alias
                }
            }
            "Ledger"
        } catch (e: Exception) {
            "Ledger"
        }
    }
}

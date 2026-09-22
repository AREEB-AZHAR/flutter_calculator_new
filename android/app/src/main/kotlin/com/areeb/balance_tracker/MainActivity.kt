package com.areeb.balance_tracker

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.areeb.tally/app_icon"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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

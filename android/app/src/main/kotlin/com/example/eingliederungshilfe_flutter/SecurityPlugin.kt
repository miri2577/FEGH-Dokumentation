package com.example.eingliederungshilfe_flutter

import android.app.Activity
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SecurityPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "eingliederungshilfe.security")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "enableFlagSecure" -> {
                enableFlagSecure()
                result.success(null)
            }
            "disableFlagSecure" -> {
                disableFlagSecure()
                result.success(null)
            }
            "isUsbDebuggingEnabled" -> {
                result.success(isUsbDebuggingEnabled())
            }
            "isUnknownSourcesEnabled" -> {
                result.success(isUnknownSourcesEnabled())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun enableFlagSecure() {
        activity?.window?.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    private fun disableFlagSecure() {
        activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun isUsbDebuggingEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Global.getInt(
                    context?.contentResolver,
                    Settings.Global.ADB_ENABLED, 0
                ) != 0
            } else {
                Settings.Secure.getInt(
                    context?.contentResolver,
                    Settings.Secure.ADB_ENABLED, 0
                ) != 0
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isUnknownSourcesEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context?.packageManager?.canRequestPackageInstalls() ?: false
            } else {
                Settings.Secure.getInt(
                    context?.contentResolver,
                    Settings.Secure.INSTALL_NON_MARKET_APPS, 0
                ) != 0
            }
        } catch (e: Exception) {
            false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
package com.babydaily.baby_daily

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelId = "babydaily_alerts"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureNotificationChannel()

        val prefs = applicationContext.getSharedPreferences("babydaily_prefs", Context.MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.babydaily/storage")
            .setMethodCallHandler { call, result ->
                try {
                    val key = call.argument<String>("key") ?: ""
                    when (call.method) {
                        "getString" -> result.success(prefs.getString(key, null))
                        "setString" -> {
                            val value = call.argument<String>("value")
                            prefs.edit().putString(key, value).apply()
                            result.success(true)
                        }
                        "getBool" -> {
                            if (prefs.contains(key)) {
                                result.success(prefs.getBoolean(key, false))
                            } else {
                                result.success(null)
                            }
                        }
                        "setBool" -> {
                            val value = call.argument<Boolean>("value") ?: false
                            prefs.edit().putBoolean(key, value).apply()
                            result.success(true)
                        }
                        "remove" -> {
                            prefs.edit().remove(key).apply()
                            result.success(true)
                        }
                        "setAlarm" -> {
                            val hour = call.argument<Int>("hour") ?: 12
                            val minute = call.argument<Int>("minute") ?: 0
                            val message = call.argument<String>("message") ?: "BabyDaily Reminder"
                            val skipUi = call.argument<Boolean>("skipUi") ?: false
                            val ok = launchClockAlarm(hour, minute, message, skipUi)
                            result.success(ok)
                        }
                        "setTimer" -> {
                            val seconds = call.argument<Int>("seconds") ?: 10800
                            val message = call.argument<String>("message") ?: "BabyDaily Timer"
                            val skipUi = call.argument<Boolean>("skipUi") ?: false
                            val ok = launchClockTimer(seconds, message, skipUi)
                            result.success(ok)
                        }
                        "showNotification" -> {
                            val title = call.argument<String>("title") ?: "BabyDaily"
                            val body = call.argument<String>("body") ?: ""
                            requestPostNotificationsIfNeeded()
                            showSystemNotification(title, body)
                            result.success(true)
                        }
                        "scheduleNotification" -> {
                            val delayMs = (call.argument<Number>("delayMs")?.toLong() ?: 5000L).coerceAtLeast(1000L)
                            val title = call.argument<String>("title") ?: "BabyDaily"
                            val body = call.argument<String>("body") ?: ""
                            requestPostNotificationsIfNeeded()
                            mainHandler.postDelayed({
                                showSystemNotification(title, body)
                            }, delayMs)
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.success(null)
                }
            }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val ch = NotificationChannel(
                channelId,
                "BabyDaily Routine & Meal Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for next feeding, sleep, medicine, and caregiver updates"
                enableVibration(true)
            }
            nm.createNotificationChannel(ch)
        }
    }

    private fun requestPostNotificationsIfNeeded() {
        if (Build.VERSION.SDK_INT >= 33) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001)
            }
        }
    }

    private fun showSystemNotification(title: String, body: String) {
        try {
            ensureNotificationChannel()
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val tapIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, 0, tapIntent, pendingFlags)

            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, channelId)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(this)
            }

            builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(body)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)

            nm.notify((System.currentTimeMillis() % 100000).toInt(), builder.build())
        } catch (_: Exception) {
        }
    }

    private fun launchClockAlarm(hour: Int, minute: Int, message: String, skipUi: Boolean): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, skipUi)
                putExtra(AlarmClock.EXTRA_VIBRATE, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            showSystemNotification("⏰ $message", String.format("Alarm set for %02d:%02d", hour, minute))
            false
        }
    }

    private fun launchClockTimer(seconds: Int, message: String, skipUi: Boolean): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_TIMER).apply {
                putExtra(AlarmClock.EXTRA_LENGTH, seconds)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, skipUi)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }
}

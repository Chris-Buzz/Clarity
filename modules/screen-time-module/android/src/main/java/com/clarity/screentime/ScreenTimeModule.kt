package com.clarity.screentime

import android.app.AppOpsManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import com.facebook.react.bridge.*

class ScreenTimeModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private var blockedApps: MutableSet<String> = mutableSetOf()
    private var isBlocking = false

    override fun getName(): String {
        return "ScreenTimeModule"
    }

    @ReactMethod
    fun checkAuthorization(promise: Promise) {
        try {
            val hasUsageAccess = hasUsageStatsPermission()
            val hasOverlayPermission = Settings.canDrawOverlays(reactApplicationContext)
            promise.resolve(hasUsageAccess && hasOverlayPermission)
        } catch (e: Exception) {
            promise.reject("CHECK_AUTH_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun requestAuthorization(promise: Promise) {
        try {
            val hasUsageAccess = hasUsageStatsPermission()
            val hasOverlayPermission = Settings.canDrawOverlays(reactApplicationContext)

            if (!hasUsageAccess) {
                // Open usage access settings
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                reactApplicationContext.startActivity(intent)
            }

            if (!hasOverlayPermission) {
                // Open overlay permission settings
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:" + reactApplicationContext.packageName)
                )
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                reactApplicationContext.startActivity(intent)
            }

            // Return current status (user needs to grant and come back)
            promise.resolve(hasUsageAccess && hasOverlayPermission)
        } catch (e: Exception) {
            promise.reject("REQUEST_AUTH_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun getInstalledApps(promise: Promise) {
        try {
            val pm = reactApplicationContext.packageManager
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

            val appList = WritableNativeArray()

            for (app in apps) {
                // Filter to only show user-installed apps (not system apps)
                if ((app.flags and ApplicationInfo.FLAG_SYSTEM) == 0) {
                    val appInfo = WritableNativeMap()
                    appInfo.putString("packageName", app.packageName)
                    appInfo.putString("name", pm.getApplicationLabel(app).toString())

                    // Get app icon as base64 (optional - can be resource intensive)
                    // val icon = pm.getApplicationIcon(app.packageName)

                    appList.pushMap(appInfo)
                }
            }

            promise.resolve(appList)
        } catch (e: Exception) {
            promise.reject("GET_APPS_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun setBlockedApps(appPackages: ReadableArray, promise: Promise) {
        try {
            blockedApps.clear()
            for (i in 0 until appPackages.size()) {
                appPackages.getString(i)?.let { blockedApps.add(it) }
            }
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("SET_BLOCKED_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun startBlocking(promise: Promise) {
        try {
            if (!hasUsageStatsPermission() || !Settings.canDrawOverlays(reactApplicationContext)) {
                promise.reject("NO_PERMISSION", "Missing required permissions")
                return
            }

            isBlocking = true

            // Start the blocking service
            val intent = Intent(reactApplicationContext, AppBlockerService::class.java)
            intent.putStringArrayListExtra("blocked_apps", ArrayList(blockedApps))

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                reactApplicationContext.startForegroundService(intent)
            } else {
                reactApplicationContext.startService(intent)
            }

            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("START_BLOCKING_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun stopBlocking(promise: Promise) {
        try {
            isBlocking = false

            // Stop the blocking service
            val intent = Intent(reactApplicationContext, AppBlockerService::class.java)
            reactApplicationContext.stopService(intent)

            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("STOP_BLOCKING_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun startFocusSession(durationMinutes: Double, promise: Promise) {
        try {
            if (!hasUsageStatsPermission()) {
                // Fall back to non-blocking mode
                promise.resolve(true)
                return
            }

            isBlocking = true

            // Start the blocking service with duration
            val intent = Intent(reactApplicationContext, AppBlockerService::class.java)
            intent.putStringArrayListExtra("blocked_apps", ArrayList(blockedApps))
            intent.putExtra("duration_minutes", durationMinutes.toLong())

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                reactApplicationContext.startForegroundService(intent)
            } else {
                reactApplicationContext.startService(intent)
            }

            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("START_SESSION_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun endFocusSession(promise: Promise) {
        stopBlocking(promise)
    }

    /**
     * Enable always-on friction mode - runs 24/7 until disabled
     * This is the main feature: adds friction to social media apps all the time
     */
    @ReactMethod
    fun enableAlwaysOnFriction(frictionLevel: Int, promise: Promise) {
        try {
            if (!hasUsageStatsPermission() || !Settings.canDrawOverlays(reactApplicationContext)) {
                promise.reject("NO_PERMISSION", "Missing required permissions. Please grant Usage Access and Overlay permissions.")
                return
            }

            if (blockedApps.isEmpty()) {
                promise.reject("NO_APPS", "No apps selected for friction. Please select apps first.")
                return
            }

            isBlocking = true

            // Start always-on service (no duration = runs forever)
            val intent = Intent(reactApplicationContext, AppBlockerService::class.java)
            intent.putStringArrayListExtra("blocked_apps", ArrayList(blockedApps))
            intent.putExtra("friction_level", frictionLevel)
            intent.putExtra("always_on", true) // Key flag for always-on mode
            // No duration_minutes = runs indefinitely

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                reactApplicationContext.startForegroundService(intent)
            } else {
                reactApplicationContext.startService(intent)
            }

            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ENABLE_FRICTION_ERROR", e.message, e)
        }
    }

    /**
     * Disable always-on friction mode
     */
    @ReactMethod
    fun disableAlwaysOnFriction(promise: Promise) {
        stopBlocking(promise)
    }

    /**
     * Check if always-on friction is currently active
     */
    @ReactMethod
    fun isAlwaysOnFrictionEnabled(promise: Promise) {
        promise.resolve(isBlocking)
    }

    @ReactMethod
    fun openUsageSettings(promise: Promise) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            reactApplicationContext.startActivity(intent)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("OPEN_SETTINGS_ERROR", e.message, e)
        }
    }

    @ReactMethod
    fun getCurrentForegroundApp(promise: Promise) {
        try {
            if (!hasUsageStatsPermission()) {
                promise.resolve(null)
                return
            }

            val usageStatsManager = reactApplicationContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 1000 * 60 // Last minute

            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            if (usageStatsList.isNullOrEmpty()) {
                promise.resolve(null)
                return
            }

            val sortedStats = usageStatsList.sortedByDescending { it.lastTimeUsed }
            val mostRecent = sortedStats.firstOrNull()

            if (mostRecent != null) {
                val result = WritableNativeMap()
                result.putString("packageName", mostRecent.packageName)
                result.putDouble("lastTimeUsed", mostRecent.lastTimeUsed.toDouble())
                promise.resolve(result)
            } else {
                promise.resolve(null)
            }
        } catch (e: Exception) {
            promise.reject("GET_FOREGROUND_ERROR", e.message, e)
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = reactApplicationContext.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                reactApplicationContext.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                reactApplicationContext.packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }
}

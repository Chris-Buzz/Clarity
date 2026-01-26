package com.clarity.screentime

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.*
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Service that monitors app usage and shows friction challenges:
 * 1. When user first opens a blocked app
 * 2. PERIODICALLY while they're using the app (doom scroll interruption)
 *
 * The periodic interruption is the key feature - it makes doom scrolling
 * annoying by constantly interrupting with challenges.
 */
class AppBlockerService : Service() {

    private var blockedApps: Set<String> = emptySet()
    private var handler: Handler? = null
    private var checkRunnable: Runnable? = null
    private var durationMinutes: Long = 0
    private var sessionStartTime: Long = 0
    private var frictionLevel: Int = 1
    private var isAlwaysOn: Boolean = false // Key flag: runs 24/7 when true

    // Track current blocked app usage
    private var currentBlockedApp: String? = null
    private var lastChallengeShownTime: Long = 0
    private var isChallengeVisible: Boolean = false

    // Apps temporarily allowed after completing a challenge (package -> expiry time)
    private var temporarilyAllowed: MutableMap<String, Long> = mutableMapOf()

    // Challenge intervals: how often to interrupt during doom scrolling
    private fun getChallengeIntervalMs(): Long {
        return when (frictionLevel) {
            1 -> 5 * 60 * 1000L   // Gentle: every 5 minutes
            2 -> 2 * 60 * 1000L   // Moderate: every 2 minutes
            3 -> 45 * 1000L       // Warrior: every 45 seconds!
            else -> 3 * 60 * 1000L
        }
    }

    // How long access is granted after completing a challenge
    private fun getAllowedDurationMs(): Long {
        return when (frictionLevel) {
            1 -> 5 * 60 * 1000L   // Gentle: 5 minutes of access
            2 -> 2 * 60 * 1000L   // Moderate: 2 minutes
            3 -> 45 * 1000L       // Warrior: only 45 seconds!
            else -> 3 * 60 * 1000L
        }
    }

    private val allowAppReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val pkg = intent?.getStringExtra("package") ?: return
            val now = System.currentTimeMillis()
            temporarilyAllowed[pkg] = now + getAllowedDurationMs()
            lastChallengeShownTime = now
            isChallengeVisible = false
        }
    }

    private val challengeDismissedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            isChallengeVisible = false
        }
    }

    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "clarity_focus_channel"
        private const val NOTIFICATION_ID = 1001
        private const val CHECK_INTERVAL_MS = 500L
    }

    override fun onCreate() {
        super.onCreate()
        handler = Handler(Looper.getMainLooper())
        createNotificationChannel()

        // Register receivers
        val allowFilter = IntentFilter("com.clarity.ALLOW_APP_TEMPORARILY")
        val dismissFilter = IntentFilter("com.clarity.CHALLENGE_DISMISSED")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(allowAppReceiver, allowFilter, RECEIVER_NOT_EXPORTED)
            registerReceiver(challengeDismissedReceiver, dismissFilter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(allowAppReceiver, allowFilter)
            registerReceiver(challengeDismissedReceiver, dismissFilter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            blockedApps = it.getStringArrayListExtra("blocked_apps")?.toSet() ?: emptySet()
            durationMinutes = it.getLongExtra("duration_minutes", 0)
            frictionLevel = it.getIntExtra("friction_level", 1)
            isAlwaysOn = it.getBooleanExtra("always_on", false)
            sessionStartTime = System.currentTimeMillis()
        }

        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        startMonitoring()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopMonitoring()
        try {
            unregisterReceiver(allowAppReceiver)
            unregisterReceiver(challengeDismissedReceiver)
        } catch (e: Exception) { }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Focus Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Active during focus sessions"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val levelName = when (frictionLevel) {
            1 -> "Gentle"
            2 -> "Moderate"
            3 -> "Warrior"
            else -> "Active"
        }

        val title = if (isAlwaysOn) {
            "Friction Active: $levelName"
        } else {
            "Focus Mode: $levelName"
        }

        val text = if (isAlwaysOn) {
            "Making ${blockedApps.size} apps harder to doom scroll"
        } else {
            "${blockedApps.size} apps monitored with periodic challenges"
        }

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startMonitoring() {
        checkRunnable = object : Runnable {
            override fun run() {
                checkForegroundApp()

                // Only check duration for focus sessions, not always-on mode
                if (!isAlwaysOn && durationMinutes > 0) {
                    val elapsed = System.currentTimeMillis() - sessionStartTime
                    if (elapsed >= durationMinutes * 60 * 1000) {
                        stopSelf()
                        return
                    }
                }
                // Always-on mode: runs forever until manually disabled

                handler?.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
        handler?.post(checkRunnable!!)
    }

    private fun stopMonitoring() {
        checkRunnable?.let { handler?.removeCallbacks(it) }
        checkRunnable = null
    }

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val endTime = System.currentTimeMillis()
        val startTime = endTime - 10000

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        ) ?: return

        val currentApp = usageStatsList
            .sortedByDescending { it.lastTimeUsed }
            .firstOrNull()?.packageName ?: return

        // Ignore our app and system apps
        if (currentApp == packageName ||
            currentApp.startsWith("com.android.") ||
            currentApp.startsWith("com.google.android.inputmethod")) {
            currentBlockedApp = null
            return
        }

        if (blockedApps.contains(currentApp)) {
            handleBlockedApp(currentApp)
        } else {
            currentBlockedApp = null
        }
    }

    private fun handleBlockedApp(appPackage: String) {
        val now = System.currentTimeMillis()

        // Don't show multiple challenges
        if (isChallengeVisible) return

        // Check if temporarily allowed
        val allowedUntil = temporarilyAllowed[appPackage]
        if (allowedUntil != null && now < allowedUntil) {
            // App is allowed, but check if it's time for ANOTHER challenge
            // This is the doom scroll interruption!
            val timeSinceLastChallenge = now - lastChallengeShownTime

            if (timeSinceLastChallenge >= getChallengeIntervalMs()) {
                // Time to interrupt the doom scrolling!
                showChallenge(appPackage, isInterruption = true)
            }
            return
        }

        // App not allowed - show initial challenge
        currentBlockedApp = appPackage
        showChallenge(appPackage, isInterruption = false)
    }

    private fun showChallenge(appPackage: String, isInterruption: Boolean) {
        isChallengeVisible = true
        lastChallengeShownTime = System.currentTimeMillis()

        val intent = Intent(this, BlockingActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("blocked_app", appPackage)
            putExtra("friction_level", frictionLevel)
            putExtra("is_interruption", isInterruption)
        }
        startActivity(intent)
    }
}

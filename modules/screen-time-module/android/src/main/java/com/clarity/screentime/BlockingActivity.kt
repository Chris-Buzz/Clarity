package com.clarity.screentime

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import kotlin.random.Random

/**
 * Full-screen activity that appears when user tries to open a blocked app.
 * Shows a friction challenge that must be completed to access the app.
 */
class BlockingActivity : Activity() {

    private var blockedAppPackage: String? = null
    private var frictionLevel: Int = 1
    private var isInterruption: Boolean = false
    private var challengeAnswer: Int = 0
    private var typingChallenge: String = ""

    // Interruption messages to remind user they're doom scrolling
    private val interruptionTitles = listOf(
        "⏰ Time Check!",
        "🤔 Still scrolling?",
        "⚡ Focus Break!",
        "🎯 Quick Check-in",
        "💭 Mindful Moment"
    )

    private val interruptionMessages = listOf(
        "You've been scrolling for a while.\nIs this really how you want to spend your time?",
        "Your focus session is still active.\nComplete this challenge to keep scrolling.",
        "Just checking in!\nAre you being intentional with your time?",
        "Time flies when doom scrolling.\nHere's a quick challenge to slow down.",
        "Remember your goals?\nComplete this to continue browsing."
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        blockedAppPackage = intent.getStringExtra("blocked_app")
        frictionLevel = intent.getIntExtra("friction_level", 1)
        isInterruption = intent.getBooleanExtra("is_interruption", false)

        val layout = createChallengeLayout()
        setContentView(layout)
    }

    private fun createChallengeLayout(): View {
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF121212.toInt())
            setPadding(48, 48, 48, 48)
        }

        // Title - different for interruptions
        val titleText = if (isInterruption) {
            interruptionTitles.random()
        } else {
            "🔥 Stay Focused!"
        }

        val title = TextView(this).apply {
            text = titleText
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }
        mainLayout.addView(title)

        // Subtitle - different for interruptions
        val subtitleText = if (isInterruption) {
            interruptionMessages.random()
        } else {
            "You're trying to open a blocked app.\nComplete this challenge to continue."
        }

        val subtitle = TextView(this).apply {
            text = subtitleText
            textSize = 16f
            setTextColor(0xAAFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }
        mainLayout.addView(subtitle)

        // Add challenge based on friction level
        when (frictionLevel) {
            1 -> addLevel1Challenge(mainLayout)
            2 -> addLevel2Challenge(mainLayout)
            else -> addLevel3Challenge(mainLayout)
        }

        // Back to Clarity button
        val backButton = Button(this).apply {
            text = "Return to Focus"
            textSize = 16f
            setTextColor(0xFF22c55e.toInt())
            setBackgroundColor(0x2222c55e.toInt())
            setPadding(48, 24, 48, 24)
            setOnClickListener { returnToClarity() }
        }

        val backParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            topMargin = 32
        }
        mainLayout.addView(backButton, backParams)

        return mainLayout
    }

    private fun addLevel1Challenge(parent: LinearLayout) {
        // Simple confirmation - just a button
        val confirmText = TextView(this).apply {
            text = "Are you sure you want to break your focus?"
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        parent.addView(confirmText)

        val confirmButton = Button(this).apply {
            text = "Yes, I understand"
            textSize = 16f
            setTextColor(0xFFef4444.toInt())
            setBackgroundColor(0x22ef4444.toInt())
            setPadding(48, 24, 48, 24)
            setOnClickListener { allowAccess() }
        }
        parent.addView(confirmButton)
    }

    private fun addLevel2Challenge(parent: LinearLayout) {
        // Breathing exercise countdown
        val breatheText = TextView(this).apply {
            text = "Take 3 deep breaths first.\n\nBreathe in... hold... breathe out..."
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        parent.addView(breatheText)

        val countdownText = TextView(this).apply {
            text = "Wait 10 seconds..."
            textSize = 24f
            setTextColor(0xFFf59e0b.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        parent.addView(countdownText)

        val continueButton = Button(this).apply {
            text = "Continue anyway"
            textSize = 16f
            setTextColor(0x66FFFFFF.toInt())
            setBackgroundColor(0x11FFFFFF.toInt())
            setPadding(48, 24, 48, 24)
            isEnabled = false
        }

        // Countdown timer
        var secondsLeft = 10
        val handler = android.os.Handler(mainLooper)
        val runnable = object : Runnable {
            override fun run() {
                secondsLeft--
                if (secondsLeft > 0) {
                    countdownText.text = "Wait $secondsLeft seconds..."
                    handler.postDelayed(this, 1000)
                } else {
                    countdownText.text = "You may continue"
                    continueButton.isEnabled = true
                    continueButton.setTextColor(0xFFef4444.toInt())
                    continueButton.setBackgroundColor(0x22ef4444.toInt())
                }
            }
        }
        handler.postDelayed(runnable, 1000)

        continueButton.setOnClickListener { allowAccess() }
        parent.addView(continueButton)
    }

    private fun addLevel3Challenge(parent: LinearLayout) {
        // Random challenge: math or typing
        val challengeType = Random.nextInt(2)

        if (challengeType == 0) {
            addMathChallenge(parent)
        } else {
            addTypingChallenge(parent)
        }
    }

    private fun addMathChallenge(parent: LinearLayout) {
        // Generate math problem
        val num1 = Random.nextInt(10, 50)
        val num2 = Random.nextInt(10, 50)
        val num3 = Random.nextInt(5, 20)
        challengeAnswer = num1 + num2 - num3

        val challengeText = TextView(this).apply {
            text = "Solve this to continue:\n\n$num1 + $num2 - $num3 = ?"
            textSize = 22f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        parent.addView(challengeText)

        val input = EditText(this).apply {
            hint = "Your answer"
            textSize = 20f
            setTextColor(0xFFFFFFFF.toInt())
            setHintTextColor(0x66FFFFFF.toInt())
            setBackgroundColor(0x22FFFFFF.toInt())
            setPadding(32, 24, 32, 24)
            gravity = Gravity.CENTER
            inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_SIGNED
        }

        val inputParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomMargin = 24
        }
        parent.addView(input, inputParams)

        val submitButton = Button(this).apply {
            text = "Submit"
            textSize = 16f
            setTextColor(0xFFef4444.toInt())
            setBackgroundColor(0x22ef4444.toInt())
            setPadding(48, 24, 48, 24)
            setOnClickListener {
                val userAnswer = input.text.toString().toIntOrNull()
                if (userAnswer == challengeAnswer) {
                    allowAccess()
                } else {
                    Toast.makeText(this@BlockingActivity, "Wrong answer. Try again!", Toast.LENGTH_SHORT).show()
                    input.text.clear()
                }
            }
        }
        parent.addView(submitButton)
    }

    private fun addTypingChallenge(parent: LinearLayout) {
        // Generate typing challenge
        val phrases = listOf(
            "I choose focus over distraction",
            "My goals matter more than this",
            "I am in control of my attention",
            "This can wait until later",
            "I will not let this app control me"
        )
        typingChallenge = phrases.random()

        val challengeText = TextView(this).apply {
            text = "Type this phrase exactly:\n\n\"$typingChallenge\""
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        parent.addView(challengeText)

        val input = EditText(this).apply {
            hint = "Type here..."
            textSize = 16f
            setTextColor(0xFFFFFFFF.toInt())
            setHintTextColor(0x66FFFFFF.toInt())
            setBackgroundColor(0x22FFFFFF.toInt())
            setPadding(32, 24, 32, 24)
            gravity = Gravity.CENTER
        }

        val inputParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            bottomMargin = 24
        }
        parent.addView(input, inputParams)

        val submitButton = Button(this).apply {
            text = "Submit"
            textSize = 16f
            setTextColor(0xFFef4444.toInt())
            setBackgroundColor(0x22ef4444.toInt())
            setPadding(48, 24, 48, 24)
            setOnClickListener {
                if (input.text.toString().trim().equals(typingChallenge, ignoreCase = true)) {
                    allowAccess()
                } else {
                    Toast.makeText(this@BlockingActivity, "Doesn't match. Type it exactly!", Toast.LENGTH_SHORT).show()
                }
            }
        }
        parent.addView(submitButton)
    }

    private fun allowAccess() {
        // User completed the challenge - let them access the app temporarily
        // Send broadcast to service to allow this app for 5 minutes
        val intent = Intent("com.clarity.ALLOW_APP_TEMPORARILY")
        intent.putExtra("package", blockedAppPackage)
        intent.putExtra("duration_minutes", 5)
        sendBroadcast(intent)

        // Open the blocked app
        blockedAppPackage?.let { pkg ->
            val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
            if (launchIntent != null) {
                startActivity(launchIntent)
            }
        }
        finish()
    }

    private fun returnToClarity() {
        // Go back to Clarity app
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
        finish()
    }

    override fun onBackPressed() {
        // Don't allow back button to bypass the challenge
        returnToClarity()
    }
}

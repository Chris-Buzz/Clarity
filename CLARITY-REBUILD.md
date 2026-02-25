# Clarity Rebuild: Patience & Dopamine Rewiring

## READ THIS FIRST

This document is the blueprint for rebuilding Clarity from a screen time / prosocial friction app into a **patience training + dopamine rewiring** app. The core pivot: Clarity doesn't just block apps — it teaches your brain to be patient again.

The Focus Timer feature is being **kept**. Most other features are being **dropped or replaced**. See the file audit below for exact keep/drop/modify decisions.

---

## New Vision

Clarity is now about three things:
1. **Smart Friction** — Breathing gates, progressive delays, and countdown unlocks when opening blocked apps
2. **Dopamine Rewiring** — Scroll friction, escalating delays, and structured 30-day training program
3. **Patience in Daily Life** — Challenges, fog journal, thought untangler, calendar-protected breathing room

**Tagline:** "Don't just block apps. Rewire your brain."

**Tone:** Still a friend with a smirk, not a parent lecturing. But now also a *coach* — encouraging, not punishing.

---

## FILE AUDIT: What to Keep, Drop, and Modify

### ✅ KEEP AS-IS (Core Infrastructure)
These files are foundational and stay untouched:

```
ClarityApp.swift                          — Entry point, SwiftData setup
Views/App/TabContainer.swift              — Custom tab bar (update tab names)
Views/App/ContentView.swift               — Root view
Utilities/ClarityColors.swift             — Design system colors
Utilities/ClarityFonts.swift              — Font definitions
Utilities/ClaritySpacing.swift            — Spacing constants
Utilities/Color+Hex.swift                 — Color extension
Utilities/HapticManager.swift             — Haptic feedback
Utilities/Date+Helpers.swift              — Date utilities
Views/Shared/ClarityButton.swift          — Reusable button component
Views/Shared/AnimatedBackground.swift     — Background visual
Services/AppGroupStorage.swift            — App Group UserDefaults communication
Services/NotificationService.swift        — Push notification handling
Services/ScreenTimeService.swift          — FamilyControls/ManagedSettings/DeviceActivity (CORE)
Services/SubscriptionService.swift        — StoreKit 2 subscriptions
Services/DataCleanupService.swift         — Background cleanup
Extensions/ShieldConfiguration/           — Shield UI extension (MODIFY heavily)
Extensions/ShieldAction/                  — Shield interaction extension (MODIFY heavily)
Extensions/DeviceActivityMonitor/         — Usage threshold monitoring (KEEP)
Extensions/DeviceActivityReport/          — Usage reporting (KEEP)
Extensions/ClarityWidget/                 — Widget (KEEP, update content later)
Clarity.entitlements                      — Entitlements file
Info.plist                                — App config
```
 
### ✅ KEEP + MODIFY (Evolving Features)
These files stay but need significant changes:

```
ViewModels/AppState.swift
  → Remove: prosocialEngine, wifiGateService references
  → Add: patienceManager, fogJournalManager, countdownManager
  → Update tab enum to: .dashboard, .patience, .settings

ViewModels/ProgressiveFrictionManager.swift
  → MAJOR REWRITE: Replace prosocial friction levels with patience-based levels:
    Level 1: Awareness toast (keep)
    Level 2: Breathing gate (6-second forced breath — proven most effective)
    Level 3: Intent declaration ("What are you opening this for?")
    Level 4: Progressive countdown (escalating delay timer)
    Level 5: Scroll friction shield (slow-scroll content before re-entry)
  → Remove all prosocial text/call references
  → Add progressive delay escalation (1st open: 5s, 2nd: 10s, 3rd: 20s, etc.)

Services/AdaptiveFrictionEngine.swift
  → Keep doomscroll detection logic (it's excellent)
  → Keep pickup tracking and bypass counting
  → Remove emergency unlock wait escalation (replace with countdown system)
  → Add: daily patience score calculation based on bypasses vs completions

Models/UserProfile.swift
  → Remove: WiFi gate fields, prosocial fields
  → Add: patienceLevel (Int), fogEntries count, challengeStreak,
    dopamineProgramDay (Int, 0-30), countdownEscalationBase (Int seconds)

Views/Dashboard/DashboardView.swift
  → MAJOR REWRITE: New dashboard focused on:
    - Patience Score (replaces Clarity Score — based on friction completions, 
      challenge completions, fog journal entries, program progress)
    - Today's countdown escalation status ("Next unlock: 15 seconds")
    - Active patience challenge
    - Fog clarity level
    - Focus timer quick start (keep)
  → Remove: ConnectionStatsCard, ImportantPeopleStrip, BudgetStatusCard
  → Remove: FrictionIntensityCard (replace with patience progress)

Views/Dashboard/ClarityScoreRing.swift
  → Rename to PatienceScoreRing.swift, update visuals

ViewModels/ClarityScoreCalculator.swift
  → Rename to PatienceScoreCalculator.swift
  → New formula: friction completions (40%) + challenges done (25%) + 
    fog journal consistency (15%) + program progress (20%)

ViewModels/SessionManager.swift
  → Keep for Focus Timer functionality (no changes needed)
```

### ✅ KEEP + REPURPOSE (Good Bones, New Purpose)
```
Views/Focus/FocusTimerView.swift          — KEEP exactly as-is
Views/Focus/CandleVisual.swift            — KEEP exactly as-is
Views/Focus/BreathingOverlay.swift        — KEEP (used in breathing gate friction)
Views/Focus/ReflectionView.swift          — Modify for post-session patience reflection

Views/Friction/BreathingShield.swift      — KEEP (this IS the breathing gate)
Views/Friction/IntentionCheck.swift       — KEEP + modify to be "Intent Declaration"
Views/Friction/FrictionOverlay.swift      — REWRITE to use new 5 patience levels
Views/Friction/AwarenessToast.swift       — KEEP as level 1 friction
Views/Friction/StrongEncouragement.swift  — Modify to be "Patience Encouragement"

Views/Shared/MoodCheckIn.swift            — Repurpose as "Fog Check-In" (1-5 clarity scale)

Views/Insights/InsightsView.swift         — REWRITE as patience analytics
Views/Insights/WeeklyTrendSparkline.swift — KEEP (useful for patience trends)
Views/Insights/WeeklyReportView.swift     — REWRITE for patience-focused weekly report
Views/Insights/MoodTrendChart.swift       — Repurpose as FogTrendChart

Views/Settings/SettingsView.swift         — MODIFY: remove WiFi/prosocial settings,
                                            add patience training settings
Views/Settings/FrictionConfigView.swift   — MODIFY: countdown base delay config,
                                            escalation speed, breathing gate duration
Views/Settings/BudgetConfigView.swift     — KEEP: daily time budget is still relevant

Views/Subscription/SubscriptionView.swift — MODIFY: update feature list for new premium
Views/Subscription/SubscriptionBadge.swift — KEEP

Views/Budget/BudgetStatusCard.swift       — KEEP (daily budget is still useful)
Views/Budget/EmergencyUnlockView.swift    — REWRITE as countdown unlock view

Models/FocusSession.swift                 — KEEP (focus timer data)
Models/MoodEntry.swift                    — Repurpose as FogEntry.swift
Models/DailySnapshot.swift                — MODIFY: add patience metrics
Models/Achievement.swift                  — MODIFY: patience-themed achievements
Models/ImplementationIntention.swift      — KEEP (if-then plans still valuable)
Models/SubstitutionRecord.swift           — KEEP (habit substitution still relevant)

Services/HealthKitService.swift           — KEEP (sleep/activity correlations)
Services/FocusSessionBlockingService.swift — KEEP (block apps during focus timer)
Services/DailyBudgetService.swift         — KEEP (daily time budget)
```

### 🗑️ DROP (No Longer Relevant)
```
# Prosocial System (entire feature removed)
Views/Friction/Challenges/                — DELETE entire directory
  ChallengeTemplate.swift
  DeepBreathChallenge.swift
  DrinkWaterChallenge.swift
  IntentionChallenge.swift
  GratitudeChallenge.swift
  WaitChallenge.swift
  WalkAwayChallenge.swift
  CallSomeoneChallenge.swift
  TextLovedOneChallenge.swift
  ContactParentChallenge.swift
  GoOutsideChallenge.swift
  AIVerifiedChallenge.swift

Views/Friction/ProsocialChallengeView.swift  — DELETE
Views/Friction/ConnectionStatsCard.swift     — DELETE
Views/Friction/ImportantPeopleStrip.swift     — DELETE
Views/Friction/ReflectionShield.swift         — DELETE (replaced by scroll friction)

Views/Dashboard/FrictionIntensityCard.swift   — DELETE (replaced by patience progress)
Views/Dashboard/QuickStartButton.swift        — MODIFY or replace with patience-aware launcher

# Prosocial Models
Models/ProsocialChallenge.swift              — DELETE
Models/ConnectionLog.swift                   — DELETE
Models/ImportantContact.swift                — DELETE
Models/WiFiGateConfig.swift                  — DELETE

# Prosocial Services
Services/ProsocialChallengeEngine.swift      — DELETE
Services/CallVerificationService.swift       — DELETE
Services/CommunicationMonitorService.swift   — DELETE
Services/WiFiGateService.swift               — DELETE
Services/AIVerificationService.swift         — DELETE

# Prosocial ViewModels
ViewModels/EmotionalContextEngine.swift      — DELETE
ViewModels/HabitSubstitutionEngine.swift     — KEEP (still relevant for substitution)
ViewModels/GamificationManager.swift         — MODIFY: patience-themed XP/levels

# Onboarding (simplify heavily)
Views/Onboarding/ImportantPeopleStep.swift   — DELETE
Views/Onboarding/HomeBaseStep.swift          — DELETE (WiFi gate gone)
Views/Onboarding/IntentionBuilderStep.swift  — KEEP but simplify

# Constants
Utilities/ProsocialConstants.swift           — DELETE
```

---

## NEW FILES TO CREATE

### Models
```
Models/FogEntry.swift
  — SwiftData @Model
  — Properties: id, timestamp, clarityLevel (1-5), trigger (enum: scrolling, 
    workStress, sleep, overstimulation, unknown), notes (optional String)

Models/PatienceChallenge.swift
  — SwiftData @Model
  — Properties: id, date, challengeText, challengeType (enum: wait, analog, 
    decision, attention), durationMinutes, wasCompleted, completedAt

Models/DopamineProgram.swift
  — SwiftData @Model
  — Properties: id, startDate, currentDay (1-30), phase (enum: awareness, 
    delay, substitute, integrate), dailyLogs: [DayLog]
  — DayLog: date, impulsesCaught, delaysPracticed, notes
```

### ViewModels
```
ViewModels/PatienceManager.swift
  — @Observable class
  — Tracks: daily patience score, countdown escalation state, 
    challenges completed today, current fog level
  — Methods: calculatePatienceScore(), getNextCountdownDelay(), 
    generateDailyChallenge(), recordFrictionCompletion()

ViewModels/CountdownManager.swift
  — @Observable class
  — Manages the escalating countdown system
  — Properties: baseDelay (seconds), currentDelay, opensToday, 
    escalationMultiplier
  — Logic: each app open increases delay. Resets daily.
    Formula: delay = baseDelay * (1 + (opensToday * escalationMultiplier))
  — Persists via App Group UserDefaults so shield extensions can read
```

### Views
```
Views/Patience/PatienceDashboardTab.swift
  — New second tab (replaces Insights)
  — Shows: 30-day program progress, today's challenge, fog journal, 
    patience streak, weekly patience trend

Views/Patience/DailyPatienceChallenge.swift
  — Card showing today's challenge with accept/complete/skip actions
  — Challenge examples: "Wait 5 min before responding to that text",
    "Navigate somewhere without GPS", "Sit with a decision for 2 hours"

Views/Patience/FogJournalView.swift
  — Quick check-in: "How clear is your mind?" (1-5 scale)
  — Optional trigger selection
  — History view with trend chart
  — Correlations with screen time data

Views/Patience/ThoughtUntanglerView.swift
  — Text/voice input for brain dumps
  — Optional AI analysis (Claude API) to organize and reflect
  — "Just dump" mode with no AI — pure externalization
  — Premium feature

Views/Patience/DopamineProgramView.swift
  — 30-day structured program view
  — Phase indicator (Week 1-4)
  — Daily log entry
  — Progress visualization (slow-growing tree or similar)

Views/Patience/TheBlankView.swift
  — Intentionally empty screen
  — Just a timer and a beautiful slow gradient
  — "Permission to exist without input"
  — Accessed from dashboard or patience tab

Views/Friction/CountdownUnlockView.swift
  — Full-screen countdown timer shown when opening blocked app
  — Slow-filling circle animation (not anxious numbers)
  — Shows current delay and how many times opened today
  — Single reflection prompt during wait
  — Not skippable

Views/Friction/ScrollFrictionShield.swift
  — The doomscroll breaker
  — Custom shield content: 3-5 slow-scroll patience prompts
  — Enforced delays between scroll items
  — Completes → shield lifts for another timed window
  — Deep-links to main app for richer experience if needed
```

### Services
```
Services/CalendarIntegrationService.swift
  — EventKit integration
  — Reads calendar, identifies gaps
  — Generates "breathing room" notifications for unscheduled time
  — Pre-event grounding notifications (2 min before meetings)
  — Post-rush cooldown detection
  — Weekly pace report data
  — Premium feature
```

---

## UPDATED PROGRESSIVE FRICTION (5 Patience Levels)

| Threshold | Intervention | Description | User Must |
|-----------|-------------|-------------|-----------|
| 5 min | Awareness Toast | "You've been on for 5 min. Intentional?" | Dismiss |
| 15 min | Breathing Gate | 6-second forced breath with animation | Wait + breathe |
| 30 min | Intent Declaration | "What are you opening this for?" with options | Select reason |
| 45 min | Countdown Unlock | Escalating timer (starts 10s, increases each time) | Wait it out |
| 60 min | Scroll Friction | Slow-scroll mindful content before re-entry | Complete scroll |

Night mode (10pm-6am) still halves thresholds. Adaptive friction engine still escalates based on doomscroll detection and bypass count.

---

## COUNTDOWN ESCALATION SYSTEM

The signature feature. Each time a user opens a blocked app, the countdown gets longer:

```
Open #1: 5 seconds
Open #2: 10 seconds  
Open #3: 20 seconds
Open #4: 35 seconds
Open #5: 55 seconds
Open #6+: 60 seconds (cap)
```

Formula: `delay = min(baseDelay * fibonacci(openCount), maxDelay)`

The countdown is:
- Visually calm (slow-filling circle, not frantic numbers)
- Shows a single patience prompt during the wait
- Shows "This is open #X today"
- NOT skippable
- Resets daily at midnight
- Persisted in App Group UserDefaults so shield extensions can read it

---

## UPDATED ONBOARDING (7 Steps, down from 9)

0: Welcome ("Clarity teaches your brain to be patient again")
1: Assessment (keep — screen time self-assessment)  
2: Health Permissions (keep — sleep/activity data)
3: App Selection (keep — choose apps to apply friction to)
4: Goal Setting (keep — simplify)
5: Patience Baseline ("How patient do you feel today?" 1-10)
6: Ready (keep — "Your brain is about to change")

Removed: Important People, Home Base (WiFi), Intention Builder (move to later)

---

## UPDATED TAB STRUCTURE

| Tab | Name | Content |
|-----|------|---------|
| 1 | Dashboard | Patience score, today's stats, focus timer, active challenge, fog level |
| 2 | Patience | 30-day program, challenges, fog journal, thought untangler, The Bench |
| 3 | Settings | App selection, friction config, countdown settings, subscription, calendar |

---

## UPDATED SUBSCRIPTION TIERS

**Free:**
- App blocking (basic shield)
- Breathing gate friction (level 2)
- Basic countdown unlock (fixed 10-second delay)
- Daily patience score

**Premium ($4.99/month or $39.99/year):**
- Progressive countdown escalation
- Scroll friction shield (doomscroll breaker)
- All 5 friction levels
- Daily patience challenges
- Fog journal with pattern recognition
- Thought untangler (AI-powered)
- 30-day dopamine rewiring program
- Calendar integration (breathing room)
- The Bench
- Detailed weekly patience reports

---

## DESIGN SYSTEM UPDATES

Keep everything from existing design system. Additions:

- **Patience gradient:** Slow-shifting gradient from deep navy to dark teal, used in 
  countdown screens and The Bench
- **Countdown ring:** Circular progress that fills slowly, uses primary orange on dark surface
- **Fog scale colors:** 1 (heavy fog) = muted gray, 5 (crystal clear) = bright teal
- **New accent:** Teal (#14b8a6) as secondary to orange — used for patience/clarity indicators

---

## BUILD ORDER FOR CLAUDE CODE

**Phase 1: Clean Slate**
1. Delete all files marked 🗑️ DROP
2. Remove references to deleted files from remaining code
3. Update AppState.swift (remove old services, update tabs)
4. Update UserProfile.swift (remove old fields, add new ones)
5. Ensure project compiles with stubs

**Phase 2: Core Patience Mechanics**
6. Create CountdownManager.swift
7. Create CountdownUnlockView.swift
8. Rewrite ProgressiveFrictionManager.swift with new 5 levels
9. Rewrite FrictionOverlay.swift for new level routing
10. Update ShieldConfigurationExtension.swift for countdown display

**Phase 3: Dashboard Rebuild**
11. Rewrite DashboardView.swift with patience-focused layout
12. Create PatienceScoreRing.swift (rename from ClarityScoreRing)
13. Create PatienceScoreCalculator.swift
14. Create PatienceManager.swift

**Phase 4: Patience Tab**
15. Create FogEntry.swift model
16. Create FogJournalView.swift
17. Create PatienceChallenge.swift model
18. Create DailyPatienceChallenge.swift view
19. Create DopamineProgram.swift model
20. Create DopamineProgramView.swift
21. Create TheBlankView.swift
22. Create PatienceDashboardTab.swift (assembles all patience views)

**Phase 5: Advanced Friction**
23. Create ScrollFrictionShield.swift
24. Update BreathingShield.swift (ensure 6-second forced breath)
25. Update IntentionCheck.swift → Intent Declaration
26. Wire all friction into shield extensions

**Phase 6: Onboarding Update**
27. Simplify OnboardingFlow.swift to 7 steps
28. Delete ImportantPeopleStep.swift, HomeBaseStep.swift
29. Create PatienceBaselineStep.swift
30. Update WelcomeStep.swift messaging

**Phase 7: Settings & Subscription**
31. Update SettingsView.swift
32. Update FrictionConfigView.swift for countdown settings
33. Update SubscriptionView.swift feature list

**Phase 8: Calendar Integration (Premium)**
34. Create CalendarIntegrationService.swift
35. Wire breathing room notifications

**Phase 9: AI Features (Premium)**
36. Create ThoughtUntanglerView.swift
37. Wire Claude API for thought analysis

---

## KEY RULES (carry forward from original CLAUDE.md)

- Every interaction gets haptic feedback
- Animations use spring physics (response: 0.3, dampingFraction: 0.6)
- User ALWAYS has option to continue past friction — never locked out (except during countdown timer which is timed, not permanent)
- All data stays on device — no cloud, no accounts, no analytics
- Extension targets have 5MB memory limit
- NO emojis in the UI
- Dark mode only. Background #030303. Always.
- Playful but coaching tone — encouraging, not punishing
- @Observable classes, NOT Combine, NOT ObservableObject
- SwiftData for persistence
- App Group UserDefaults for extension communication
- Bundle ID: com.clarity-focus

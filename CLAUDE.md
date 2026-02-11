# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Clarity is a native iOS screen wellness app built with Swift and SwiftUI. It uses psychology-backed **progressive friction** (not hard blocking) — 5 escalating layers of intervention based on cumulative usage time. iOS 17+ required, iOS 18+ for full features.

Core concepts:
- **Clarity Score** — Daily 0-100 composite score (meaningful use ratio, mindful pickups, substitutions, mood, intention adherence)
- **Progressive Friction** — 5 time-based layers with prosocial challenges: Awareness (5m) → Text Someone (15m) → Intention Check (30m) → Call Someone (45m) → Strong Encouragement (60m)
- **Prosocial Friction** — Friction challenges redirect users toward real phone use (texting, calling contacts) with CXCallObserver and DeviceActivity verification
- **WiFi-Gated Unlocking** — Doomscroll apps shielded everywhere except home WiFi (NEHotspotNetwork)
- **Implementation Intentions** — If-then behavior plans (Gollwitzer's research)
- **Subscription** — StoreKit 2 ($4.99/month or $39.99/year), no custom server

## Commands

```bash
# Open in Xcode
open Clarity-iOS/Clarity.xcodeproj

# Build via command line
xcodebuild -scheme Clarity -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -project Clarity-iOS/Clarity.xcodeproj

# Clean build
xcodebuild clean -scheme Clarity -project Clarity-iOS/Clarity.xcodeproj
```

**Key:** 6 targets — main app + ShieldConfiguration + ShieldAction + DeviceActivityMonitor + DeviceActivityReport + Widget. All share App Group `group.com.clarity-focus`.

## Architecture

All source code is in `Clarity-iOS/Clarity/`.

- **UI:** SwiftUI (no UIKit except where required by extensions)
- **State:** @Observable classes (NOT Combine, NOT ObservableObject)
- **Data:** SwiftData @Model classes, persisted automatically
- **Shared state:** App Group UserDefaults for extension communication
- **Navigation:** NavigationStack with custom tab bar (text labels, no icons)
- **Bundle ID:** com.clarity-focus

### Key Files

- `ClarityApp.swift` — @main entry, SwiftData container setup, background task registration
- `ViewModels/AppState.swift` — Global navigation and user state
- `ViewModels/SessionManager.swift` — Focus session lifecycle
- `ViewModels/ProgressiveFrictionManager.swift` — 5-layer friction system with prosocial variants
- `Services/ScreenTimeService.swift` — FamilyControls + ManagedSettings + DeviceActivity
- `Services/ProsocialChallengeEngine.swift` — Contact selection, challenge generation, verification orchestration
- `Services/CallVerificationService.swift` — CXCallObserver for outgoing call verification
- `Services/CommunicationMonitorService.swift` — DeviceActivity Communication category monitoring
- `Services/WiFiGateService.swift` — SSID detection and WiFi-gated shielding
- `Services/SubscriptionService.swift` — StoreKit 2 subscription management
- `Services/DataCleanupService.swift` — 30-day auto-cleanup via BGAppRefreshTask

### Data Models (SwiftData)

- `UserProfile` — Settings, XP, level, streak, goals, assessment score
- `FocusSession` — Timer sessions with task, duration, rating, mood
- `MoodEntry` — Emotional check-ins with valence/label/context
- `DailySnapshot` — Daily aggregated Clarity Score data
- `ImplementationIntention` — If-then behavior plans
- `SubstitutionRecord` — Habit substitution tracking
- `ProsocialChallenge` — Prosocial friction challenges with verification status
- `ConnectionLog` — Call/text connection tracking
- `ImportantContact` — User's selected important people (max 5)
- `WiFiGateConfig` — Home WiFi network configuration (max 3 SSIDs)

## Design System

- **Background:** #030303 ALWAYS. Dark mode only. No light mode. Ever.
- **Surface:** #141414 (cards), #1a1a1a (elevated/modals)
- **Primary:** #f97316 (orange) — CTAs, active states, accents, glow. NEVER for body text.
- **Text:** white (headings), 0.7 (body), 0.6 (tertiary), 0.35 (muted)
- **Fonts:** Playfair Display (serif titles 34-42pt), Outfit (sans body 14-16pt), Space Mono (mono labels 9-11pt)
- **Spacing:** 8pt grid (4, 8, 16, 24, 32, 48, 64)
- **Radius:** 8, 12, 16, 24, 32

## Key Rules

- Every interaction gets haptic feedback (HapticManager.light/medium/success/warning/error)
- Animations use spring physics (response: 0.3, dampingFraction: 0.6)
- User ALWAYS has option to continue past friction — never locked out
- All data stays on device — no cloud, no accounts, no analytics
- Extension targets have 5MB memory limit — keep logic minimal
- Playful tone, not preachy — friend with a smirk, not a parent lecturing
- NO emojis in the UI

## Progressive Friction (5 Layers)

| Threshold | Intervention | Prosocial Variant | User Action |
|-----------|-------------|-------------------|-------------|
| 5 min | Awareness toast | Contact nudge | Dismiss |
| 15 min | Breathing exercise | Text someone | Complete or verify |
| 30 min | Intention check | Same | Type response |
| 45 min | Mood reflection | Call someone | Complete or verify |
| 60 min | Strong encouragement | Same | Type phrase |

## Onboarding (9 Steps)

0: Welcome → 1: Assessment → 2: Health Permissions → 3: App Selection → 4: Important People → 5: Home Base (WiFi) → 6: Goals → 7: Intentions → 8: Ready

## Build Configuration

- **Bundle ID:** com.clarity-focus
- **Orientation:** Portrait only
- **Entitlements:** Family Controls, App Groups, HealthKit, WiFi Info, StoreKit, Background Fetch
- Family Controls entitlement requires manually provisioned builds

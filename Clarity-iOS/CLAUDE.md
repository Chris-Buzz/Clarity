# CLAUDE.md

## Project Overview

Clarity is a native iOS screen wellness app built with Swift and SwiftUI. It uses
psychology-backed progressive friction (not hard blocking) to help users build
healthier phone habits. iOS 17+ required, iOS 18+ for full features (State of Mind API).

## Commands

```bash
# Open in Xcode
open Clarity.xcodeproj

# Build via command line
xcodebuild -scheme Clarity -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**Key:** 6 targets exist — main app + ShieldConfiguration + ShieldAction + DeviceActivityMonitor + DeviceActivityReport + Widget. All share App Group `group.com.clarity.focus`.

## Architecture

- **UI:** SwiftUI (no UIKit except where required by extensions)
- **State:** @Observable classes (NOT Combine, NOT ObservableObject)
- **Data:** SwiftData @Model classes, persisted automatically
- **Shared state:** App Group UserDefaults for extension communication
- **Navigation:** NavigationStack with custom tab bar (text labels, no icons)
- **Bundle ID:** com.clarity.focus

### Key Files

- `ClarityApp.swift` — @main entry, SwiftData container setup
- `ViewModels/AppState.swift` — Global navigation and user state
- `ViewModels/SessionManager.swift` — Focus session lifecycle (idle → active → paused → completed)
- `ViewModels/ProgressiveFrictionManager.swift` — 5-layer friction system with configurable thresholds
- `ViewModels/HealthManager.swift` — HealthKit reads/writes
- `ViewModels/GamificationManager.swift` — XP, 20 levels, 10 badges, streaks
- `Services/ScreenTimeService.swift` — FamilyControls + ManagedSettings + DeviceActivity

### Data Models (SwiftData)

- `UserProfile` — Settings, XP, level, streak, goals, assessment score
- `FocusSession` — Timer sessions with task, duration, rating, mood
- `MoodEntry` — Emotional check-ins with valence/label/context
- `DailySnapshot` — Daily aggregated Clarity Score data
- `ImplementationIntention` — If-then behavior plans
- `SubstitutionRecord` — Habit substitution tracking

## Design System

- **Background:** #030303 ALWAYS. Dark mode only. No light mode. Ever.
- **Surface:** #141414 (cards), #1a1a1a (elevated/modals)
- **Primary:** #f97316 (orange) — CTAs, active states, accents, glow. NEVER for body text.
- **Text:** white (headings), 0.7 (body), 0.6 (tertiary), 0.35 (muted)
- **Borders:** white 0.15 (default), 0.08 (subtle), 0.25 (emphasized)
- **Fonts:** Playfair Display (serif titles 34-42pt), Outfit (sans body 14-16pt), Space Mono (mono labels 9-11pt)
- **Spacing:** 8pt grid (4, 8, 16, 24, 32, 48, 64)
- **Radius:** 8, 12, 16, 24, 32

## Key Rules

- Every interaction gets haptic feedback (light=taps, medium=toggles, success/warning/error=outcomes)
- Animations use spring physics (response: 0.3, dampingFraction: 0.6)
- User ALWAYS has option to continue past friction — never locked out
- All data stays on device — no cloud, no accounts, no analytics
- Extension targets have 5MB memory limit — keep logic minimal
- "Go back to what I was doing" as cancel text on friction (shame phrasing intentional)

## Progressive Friction (5 Layers)

| Threshold | Intervention | User Action |
|-----------|-------------|-------------|
| 5 min | Awareness toast | Dismiss |
| 15 min | Breathing exercise (30s) | Complete → continue |
| 30 min | Intention check ("What are you hoping to find?") | Type response → continue |
| 45 min | Mood reflection + alternatives | Choose alternative or continue |
| 60 min | Strong encouragement + type "I choose to continue" | Type phrase → continue |

All thresholds user-configurable. Night mode (10pm-6am) halves thresholds.

## Gamification

- XP: 10/min focused, +25 urge resisted, +50 completion, +100 perfect session
- 20 levels: Ember → Inferno (0 to 62000 XP)
- 10 badges for milestones
- Streak multiplier: +10% per day, max 50%

## Critical Patterns

- `FamilyActivityPicker` for app selection (opaque tokens, stored in App Group)
- `DeviceActivityMonitor` thresholds trigger progressive friction timing
- `ShieldConfigurationDataSource` customizes shield UI per friction level
- HealthKit authorization requested during onboarding step 3
- App Group (`group.com.clarity.focus`) bridges main app ↔ all extensions

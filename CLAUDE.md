# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ ACTIVE REBUILD IN PROGRESS

**READ `CLARITY-REBUILD.md` BEFORE MAKING ANY CHANGES.**

Clarity is being rebuilt from a prosocial friction app into a **patience training + dopamine rewiring** app. The rebuild document contains:
- Complete file audit (what to keep, drop, modify)
- New feature specifications
- New data models
- Build order (Phase 1-9)
- Updated progressive friction system

**Start with Phase 1** (deleting dropped files and cleaning references) unless told otherwise.

---

## Project Overview

Clarity is a native iOS screen wellness app built with Swift and SwiftUI. It uses **patience-based progressive friction** — escalating interventions that train your brain to delay gratification, not just block apps. iOS 17+ required, iOS 18+ for full features.

Core concepts:
- **Patience Score** — Daily 0-100 composite (friction completions, challenges, fog journal, program progress)
- **Progressive Friction** — 5 patience-based layers: Awareness → Breathing Gate → Intent Declaration → Countdown Unlock → Scroll Friction
- **Countdown Escalation** — Each app open increases the unlock delay (5s → 10s → 20s → 35s → 55s → 60s cap). Resets daily.
- **Dopamine Rewiring** — 30-day structured CBT-based program (awareness → delay → substitute → integrate)
- **Fog Journal** — Track mental clarity, correlate with screen time patterns
- **Daily Patience Challenges** — Small exercises pushed throughout the day
- **Calendar Breathing Room** — Protect empty time in your schedule (premium)
- **Subscription** — StoreKit 2 ($4.99/month or $39.99/year)

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
- **Tabs:** Dashboard | Patience | Settings
- **Bundle ID:** com.clarity-focus

## Design System

- **Background:** #030303 ALWAYS. Dark mode only. No light mode. Ever.
- **Surface:** #141414 (cards), #1a1a1a (elevated/modals)
- **Primary:** #f97316 (orange) — CTAs, active states, accents, glow
- **Secondary:** #14b8a6 (teal) — patience/clarity indicators
- **Text:** white (headings), 0.7 (body), 0.6 (tertiary), 0.35 (muted)
- **Fonts:** Playfair Display (serif titles 34-42pt), Outfit (sans body 14-16pt), Space Mono (mono labels 9-11pt)
- **Spacing:** 8pt grid (4, 8, 16, 24, 32, 48, 64)
- **Radius:** 8, 12, 16, 24, 32

## Key Rules

- Every interaction gets haptic feedback (HapticManager.light/medium/success/warning/error)
- Animations use spring physics (response: 0.3, dampingFraction: 0.6)
- User ALWAYS has option to continue past friction — never permanently locked out
- Countdown unlock IS timed but always completes — user just has to wait
- All data stays on device — no cloud, no accounts, no analytics
- Extension targets have 5MB memory limit — keep logic minimal
- Encouraging coaching tone — not punishing, not preachy
- NO emojis in the UI

## Progressive Friction (5 Patience Levels)

| Threshold | Intervention | User Must |
|-----------|-------------|-----------|
| 5 min | Awareness Toast | Dismiss |
| 15 min | Breathing Gate (6s forced breath) | Wait + breathe |
| 30 min | Intent Declaration | Select reason |
| 45 min | Countdown Unlock (escalating timer) | Wait it out |
| 60 min | Scroll Friction (slow-scroll content) | Complete scroll |

Night mode (10pm-6am) halves thresholds. Adaptive engine escalates on doomscroll detection.

## Countdown Escalation

```
Open #1: 5s → Open #2: 10s → Open #3: 20s → Open #4: 35s → Open #5: 55s → Open #6+: 60s (cap)
```

Resets daily. Persisted in App Group UserDefaults. Displayed as calm slow-filling circle, not anxious numbers.

## Onboarding (7 Steps)

0: Welcome → 1: Assessment → 2: Health Permissions → 3: App Selection → 4: Goals → 5: Patience Baseline → 6: Ready

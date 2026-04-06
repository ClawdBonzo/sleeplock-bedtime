# SleepLock

**Bedtime enforcement & sleep streak tracker • Wake up powerful every day**

A beautiful, private SwiftUI habit tracker built with 100% on-device SwiftData. Lock in your bedtime, build unbreakable streaks, and watch your energy transform.

## Features

- **Woofz-style onboarding flow** — splash, name entry, sleep habits quiz, bedtime commitment picker, multi-select blockers, animated routine crafting, and paywall
- **Sleep streak tracking** — current streak, longest streak, and streak calendar with hit/miss visualization
- **Energy score** — rolling 7-day energy metric based on morning self-ratings (1–5 scale)
- **Daily sleep logger** — log actual bedtime, wake time, and morning energy with a 15-minute grace window
- **Streak calendar** — month-view grid with color-coded days, legend, and monthly summary stats
- **Progress charts** — bedtime consistency, energy trends, and sleep duration over 7/14/30-day ranges (Swift Charts)
- **Personalized routine builder** — timeline UI with add/edit/delete/reorder steps and default templates
- **Gentle enforcement notifications** — reminders before bedtime, at bedtime, 15 min past, and morning log prompt
- **Home screen widgets** — small and medium widgets showing streak count, tonight's bedtime, and energy score
- **RevenueCat subscriptions** — paywall with weekly/monthly/annual plans and highlighted 3-day free trial
- **Before/after energy teaser** — paywall comparison card showing life before and after consistent sleep
- **100% private** — all data stored locally on-device with SwiftData, zero network calls

## Tech Stack

- Swift 6 + SwiftUI
- SwiftData (100% local & private)
- RevenueCat (stub included, ready for API key)
- WidgetKit + Swift Charts
- MVVM + @Observable
- UserNotifications for bedtime enforcement

## Screenshots

| Onboarding | Dashboard | Streak Calendar | Progress |
|:---:|:---:|:---:|:---:|
| *Splash + quiz flow* | *Streak hero + energy score* | *Month grid with hit/miss* | *Charts + trends* |

*(Placeholder — replace with actual device screenshots after first build)*

## Quick Start

1. Open `SleepLock.xcodeproj` in Xcode 16+
2. Build & run on iOS 18+ simulator or device
3. To activate RevenueCat, add your public API key in `Services/PurchaseService.swift`

## Project Structure

```
SleepLock/
├── App/                  # Entry point, RootView, MainTabView
├── Models/               # SwiftData models (UserProfile, SleepLogEntry, RoutineStep)
├── Views/
│   ├── Onboarding/       # 7-screen onboarding flow
│   ├── Paywall/          # RevenueCat paywall with trial highlight
│   ├── Main/             # Dashboard, Logger, Calendar, Charts, Routine, Settings
│   └── Components/       # Shared UI components
├── Services/             # StreakService, NotificationService, PurchaseService
├── Theme/                # SLTheme (colors, typography, spacing) + SLComponents
├── Extensions/           # Date helpers
└── Assets.xcassets/      # App icon + accent color
SleepLockWidgets/         # WidgetKit extension (small + medium)
```

---

Built as part of a 10-app portfolio targeting $10k+/mo each.

Made with ❤️ by ClawdBonzo

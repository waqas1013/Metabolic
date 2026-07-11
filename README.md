# Workout Journal Tracker

A premium, modern Flutter application built for tracking post-workout metrics, exercises, weights, and physical comfort trends over time. Specially optimized for individuals working toward athletic, calisthenics-focused progress while monitoring back safety.

## 🚀 Key Features

* **Quick Post-Workout Journaling:** Log key metrics in under two minutes:
  * ⚡ **Energy Before Workout:** Score from 1 to 10.
  * 😊 **Enjoyment of the Session:** Score from 1 to 10.
  * 🔙 **Back Comfort:** Score from 0 to 10 (0 = no issues, 10 = severe pain).
  * 💪 **Difficulty of the Workout:** Score from 1 to 10.
  * 💡 **One Thing Improved Today:** Free-text field to document wins, form enhancements, or milestones.
  * 🏋️ **Weight & Exercise Tracking:** Add multiple exercises with exact weight values used and units (kg/lbs).
* **Workout History:** Scrollable feed of previous sessions with visual score badges, expandable details, and swipe-to-delete.
* **Smart Trends & Analytics:**
  * **Overall Metrics Over Time:** Interactive line charts mapping Energy, Enjoyment, Back Comfort, and Difficulty.
  * **Back Comfort Warning Zone:** Spot patterns and check if discomfort levels cross the safe threshold (> 5).
  * **Exercise Progression Tracker:** Select any exercise from a dropdown list to view its weight history chart.
* **Premium Aesthetics:** Sleek dark mode, frosted glassmorphism elements, vibrant gradients, and responsive visual feedback.
* **Local-First Privacy:** Powered by SQLite to keep your workout history safe on your device, requiring no external logins or internet connection.

---

## 🛠️ Tech Stack & Dependencies

* **Frontend:** Flutter & Dart
* **Database:** SQLite (via `sqflite` + `path`)
* **Data Visualization:** `fl_chart`
* **Typography:** `google_fonts` (Inter)
* **Date Formats:** `intl`

---

## 📂 Project Structure

```
lib/
├── main.dart                          # App Entry & Tab Navigation
├── database/
│   └── database_helper.dart           # SQLite Database CRUD Operations
├── models/
│   └── workout_entry.dart             # Dart models for WorkoutEntry & ExerciseLog
├── theme/
│   └── app_theme.dart                 # Custom design tokens, dark theme & gradients
├── widgets/
│   ├── glassmorphism_card.dart        # Reusable blurred card
│   ├── metric_slider.dart             # Parameter-specific slider with emoji indicators
│   ├── exercise_input_card.dart       # List row for naming exercises & entering weights
│   └── score_badge.dart               # Circular score summary card
└── screens/
    ├── home_screen.dart               # Log Workout entry form
    ├── history_screen.dart            # Scrollable history feed
    ├── trends_screen.dart             # FL Charts visualization dashboard
    └── entry_detail_screen.dart       # Expanded session detail view
```

---

## 🏁 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.
* Xcode (for iOS Simulator/Devices) or Android Studio (for Android Emulator/Devices).

### Run Locally

1. Clone this repository (or navigate to the project folder):
   ```bash
   cd "Gym App"
   ```

2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```

3. Launch on a connected device/emulator:
   ```bash
   flutter run
   ```

### Builds

* Build Android APK:
  ```bash
  flutter build apk --debug
  ```
* Build iOS App (Without signing):
  ```bash
  flutter build ios --no-codesign
  ```

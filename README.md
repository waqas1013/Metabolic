# Metabolic

A premium, modern Flutter application built for tracking post-workout metrics, exercises, weights/reps, and physical recovery/comfort trends over time. Specially optimized for individuals working toward athletic, calisthenics-focused progress while monitoring back safety.

---

## 🚀 Key Features

* **Quick Post-Workout Journaling:** Log key metrics in under two minutes:
  * ⚡ **Energy Before Workout:** Score from 1 to 10.
  * 😊 **Enjoyment of the Session:** Score from 1 to 10.
  * 🔙 **Back Comfort:** Score from 0 to 10 (0 = no issues, 10 = severe pain).
  * 💪 **Difficulty of the Workout:** Score from 1 to 10.
  * 💡 **One Thing Improved Today:** Free-text field to document wins, form enhancements, or milestones.
  * 🏋️ **Weight & Reps Progression:** Log exact weight values and reps (for calisthenics pullups/pushups). Supports kg/lbs toggle.

* **Multi-Activity Logging:**
  * 🏋️ **Gym / Strength:** Track custom exercises with weights & reps.
  * 🚶 **Walk:** Auto-hides exercise lists; input distance (km) and duration (mins).
  * 🏸 **Badminton:** Track court time duration (mins).
  * 🏃 **Other:** General active recovery logging with custom distance and duration.

* **Smart Autocomplete Search Library:**
  * Premium dark-themed autocomplete suggestions dropdown that lists options as you type.
  * Comes pre-seeded with 26 clean exercises (e.g. *Assisted Pull-ups*, *Standard or Incline Push-ups*, *Cable Face Pulls*, *Heavy Farmer's Carries*, etc.).
  * Grows automatically as you log new workouts.

* **Seamless Firebase Cloud Sync:**
  * **Email & Password Authentication:** Create an account or sign in to secure your workout history.
  * **Automatic Background Sync:** Workouts and custom exercise suggestions sync automatically between local SQLite and Cloud Firestore.
  * **Multi-Device Support:** Log in on any device to immediately pull down your complete synced workout logs.

* **Workout History:** Scrollable feed of previous sessions with visual activity badges (`🚶 Walk`, `🏸 Badminton`, `🏋️ Strength`), expandable statistics, and swipe-to-delete.

* **Smart Trends & Analytics:**
  * **Overall Metrics Over Time:** Interactive line charts mapping Energy, Enjoyment, Back Comfort, and Difficulty. Filterable by activity type (All, Gym, Walk, Badminton).
  * **Back Comfort Warning Zone:** Spot patterns and check if discomfort levels cross the safe threshold (> 5).
  * **Exercise Progression Tracker:** Select any exercise from a dropdown list to view its progression chart, with toggles for both Weight and Reps.

* **Premium Aesthetics:** Sleek dark navy theme, frosted glassmorphism elements, vibrant gradients, and responsive visual feedback.

---

## 🛠️ Tech Stack & Dependencies

* **Frontend:** Flutter & Dart
* **Local Database:** SQLite (via `sqflite` + `path`)
* **Cloud Backend:** Cloud Firestore & Firebase Auth (via `firebase_core` & `firebase_auth`)
* **Data Visualization:** `fl_chart`
* **Typography:** `google_fonts` (Inter)
* **Date Formats:** `intl`

---

## 📂 Project Structure

```
lib/
├── main.dart                          # App Entry, reactive StreamBuilder authentication routing
├── firebase_options.dart              # Firebase configuration credentials
├── database/
│   ├── database_helper.dart           # SQLite Database CRUD & Migration Upgrades
│   └── firebase_helper.dart           # Firebase authentication & Firestore sync handlers
├── models/
│   └── workout_entry.dart             # Dart models for WorkoutEntry & ExerciseLog
├── theme/
│   └── app_theme.dart                 # Custom design tokens, dark theme & gradients
├── widgets/
│   ├── glassmorphism_card.dart        # Reusable blurred card
│   ├── metric_slider.dart             # Parameter-specific slider with emoji indicators
│   ├── exercise_input_card.dart       # List row for naming exercises, weights, and reps
│   └── score_badge.dart               # Circular score summary card
└── screens/
    ├── home_screen.dart               # Log Workout entry form + Cloud account settings
    ├── history_screen.dart            # Scrollable history feed with activity badges
    ├── trends_screen.dart             # FL Charts visualization dashboard with filters
    ├── entry_detail_screen.dart       # Expanded session detail statistics view
    └── login_screen.dart              # Premium Email & Password Sign In / Sign Up form
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

3. Launch on a connected device/emulator in debug mode:
   ```bash
   flutter run
   ```

### Deploy to Physical iOS Device

To deploy the app in **Release Mode** so that it can be launched directly from your iPhone home screen at any time:

1. Connect your iPhone via USB.
2. Run the release deploy command:
   ```bash
   flutter run --release
   ```

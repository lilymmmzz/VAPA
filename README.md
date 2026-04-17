# VAPA — Voice Activated Personal Assistant

A cross-platform mobile application built with Flutter and Firebase, developed as a Final Year Project for BEng Software Engineering at the University of Bolton.

## Live Demo
🌐 **Web App:** https://vapa-app-7f59b.web.app *(requires Google Chrome)*

---

## Features
- 🎤 Voice commands with 18 command types
- 🤖 AI mood companion powered by NVIDIA NIM API / Llama 3
- 📝 Notes management with real-time sync and search
- ⏰ Reminders with date/time scheduling and overdue tracking
- 😊 Daily mood tracking with weekly averages
- ☁️ Cross-device cloud synchronisation via Firebase
- 🔒 Secure user authentication with data isolation

---

## Platforms
- ✅ Android (API 21+)
- ✅ Web (Google Chrome)
- ❌ iOS (future work)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend Framework | Flutter 3.41 / Dart 3.11 |
| State Management | Provider 6.1.1 |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| AI Companion | NVIDIA NIM API / Llama 3 |
| Speech Recognition | speech_to_text 7.0.0 |
| Text-to-Speech | flutter_tts 4.0.2 |
| Wake Word | Vosk (offline) |
| Web Deployment | Firebase Hosting |

---

## Project Structure

```
vapa/
│
├── lib/
│   ├── main.dart                         # App entry point, theme, providers
│   ├── firebase_options.dart             # Firebase configuration (not in repo)
│   │
│   ├── models/                           # Data models
│   │   ├── note.dart                     # Note data model
│   │   ├── reminder.dart                 # Reminder data model
│   │   └── mood.dart                     # Mood data model
│   │
│   ├── providers/                        # State management (Provider pattern)
│   │   ├── auth_provider.dart            # Authentication state
│   │   ├── notes_provider.dart           # Notes state and operations
│   │   ├── reminders_provider.dart       # Reminders state and operations
│   │   ├── mood_provider.dart            # Mood state and operations
│   │   └── ai_provider.dart              # AI chat state and operations
│   │
│   ├── services/                         # Business logic and API calls
│   │   ├── auth_service.dart             # Firebase Authentication service
│   │   ├── notes_service.dart            # Firestore notes operations
│   │   ├── reminders_service.dart        # Firestore reminders operations
│   │   ├── mood_service.dart             # Firestore mood operations
│   │   ├── ai_service.dart               # NVIDIA NIM API integration
│   │   └── wake_word_service.dart        # Vosk offline wake word detection
│   │
│   └── screens/                          # UI screens
│       ├── home_screen.dart              # Main navigation and Nova bottom sheet
│       │
│       ├── auth/                         # Authentication screens
│       │   └── login_screen.dart         # Login and registration screen
│       │
│       ├── notes/                        # Notes module
│       │   └── notes_screen.dart         # Notes list, create, edit, delete
│       │
│       ├── reminders/                    # Reminders module
│       │   └── reminders_screen.dart     # Reminders list and management
│       │
│       ├── mood/                         # Mood tracking module
│       │   └── mood_screen.dart          # Mood logging and AI chat
│       │
│       └── voice/                        # Voice commands module
│           └── voice_screen.dart         # Voice input and command processing
│
├── web/                                  # Web platform files
│   ├── index.html                        # Web entry point with Speech API
│   ├── manifest.json                     # PWA manifest
│   └── icons/                            # Web app icons
│
├── android/                              # Android platform files
│   └── app/
│       ├── build.gradle                  # Android build configuration
│       └── google-services.json          # Firebase Android config (not in repo)
│
├── assets/                               # Static assets
│   └── models/                           # Vosk offline speech models
│       └── vosk-model-small-en-us-0.15/ # Wake word detection model
│
├── pubspec.yaml                          # Flutter dependencies
└── README.md                             # This file
```

---

## Setup and Installation

### Prerequisites
- Flutter SDK 3.41+
- Android Studio or VS Code
- Firebase project with Authentication and Firestore enabled
- NVIDIA NIM API key from build.nvidia.com

### Steps

**1. Clone the repository:**
```bash
git clone https://github.com/lilymmmzz/VAPA.git
cd VAPA
```

**2. Install dependencies:**
```bash
flutter pub get
```

**3. Add Firebase configuration:**
- Create a Firebase project at console.firebase.google.com
- Enable Authentication and Cloud Firestore
- Run FlutterFire CLI to generate `lib/firebase_options.dart`
- Add `android/app/google-services.json`

**4. Add your API key:**

Open `lib/services/ai_service.dart` and replace:
```dart
const String _apiKey = 'YOUR_NVIDIA_API_KEY_HERE';
```
With your actual NVIDIA NIM API key from build.nvidia.com

**5. Run the app:**
```bash
# Android
flutter run

# Web
flutter run -d chrome

# Build release APK
flutter build apk --release

# Build and deploy web
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting
```

---

## Test Results

| Module | Test Cases | Passed | Pass Rate |
|---|---|---|---|
| Authentication | 6 | 6 | 100% |
| Notes Management | 5 | 5 | 100% |
| Reminders | 4 | 4 | 100% |
| Voice Commands | 5 | 5 | 100% |
| Cloud Sync | 3 | 3 | 100% |
| Mood & AI | 4 | 4 | 100% |
| **Total** | **27** | **27** | **100%** |

---

## Performance

| Metric | Target | Achieved |
|---|---|---|
| App launch time | < 3 seconds | 1.8 seconds |
| UI response time | < 100ms | 80ms |
| Firestore sync latency | < 2 seconds | 1.2 seconds |
| Voice recognition accuracy | 90%+ | 95% (quiet environments) |
| SUS usability score | > 70 | 78.5 — Good |

---

## Academic Context

| | |
|---|---|
| **Degree** | BEng (Hons) Software Engineering |
| **Module** | SWE6010 — Final Year Project |
| **University** | University of Bolton |
| **Supervisor** | Dr. Fathima KS |
| **Student ID** | 2524808 |
| **Year** | 2025–2026 |

---

## License
This project was developed for academic purposes as part of a final year dissertation.

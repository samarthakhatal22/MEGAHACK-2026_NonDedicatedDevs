 
<div align="center">

<img src="assets/app_icon.png" alt="CivicShield Logo" width="100"/>

# 🛡️ CivicShield

**AI-powered civic integrity app for Indian citizens**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-^3.11.0-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Groq](https://img.shields.io/badge/Groq-LLaMA_4-FF6B35?style=flat-square)](https://groq.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

*Built for **MEGAHACK-2026** by Team **NonDedicatedDevs***

[Features](#-features) · [Screenshots](#-screenshots) · [Tech Stack](#-tech-stack) · [Getting Started](#-getting-started) · [Architecture](#-architecture) · [Contributing](#-contributing)

</div>

---

## 🎯 What is CivicShield?

CivicShield is a Flutter-based mobile and desktop application that empowers Indian citizens to navigate the digital information landscape with confidence. In an era of rampant misinformation and rising cyber fraud, CivicShield brings together AI fact-checking, government policy tracking, and scam alerts into a single, unified platform.

> **"Empowering citizens with truth, transparency, and trust."**

---

## ✨ Features

### 🔍 AI Fact Checker
- Verify news, claims, or images using **Groq LLaMA 4 Scout**
- Supports text input, image upload (gallery/camera), and image URLs
- Returns an **accuracy score**, verdict (True / False / Misleading), easy explanation, source references, and an AI-generated content flag
- Full fact-check history saved per user in Firestore

### 📜 Government Policy Tracker
- Stay up to date on key Indian policies: **Digital India Act, NEP, PDPB, Green Hydrogen Mission**, and more
- Dashboard KPIs: Total Policies, Updated, Pending, Conflicts
- Policy status chips: Active, Draft, Conflict, Under Review

### 🚨 Cyber Scam Alerts
- Live scam feed powered by **RapidAPI Cyber Security News**
- Smart fallback to curated, high-priority Indian scam alerts (Digital Arrest Scam, Bank KYC Phishing, Fake Trading Apps, etc.)
- Risk levels (**High / Medium / Low**) inferred by keyword analysis

### 👤 User Profile & Preferences
- Real-time profile from Firestore
- Fact-check activity stats
- Push notification and email alert toggles
- Dark / Light mode toggle

### 🔐 Authentication
- **Google OAuth** sign-in
- **Email & Password** sign-in / sign-up
- Secure session management via Firebase Auth

---

## 📱 Screenshots

> *Add screenshots here after building the app.*

| Login | Home Dashboard | Fact Checker | Scam Alerts |
|-------|---------------|--------------|-------------|
| `AuthenticatePage` | `HomePage` | `FactCheckChatPage` | `ScamsPage` |

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| **UI Framework** | Flutter (Material Design 3) |
| **Language** | Dart `^3.11.0` |
| **Auth** | Firebase Authentication (Google OAuth + Email/Password) |
| **Database** | Cloud Firestore |
| **Storage** | Cloudinary (image hosting) |
| **Push Notifications** | Firebase Cloud Messaging |
| **AI / LLM** | Groq API — `meta-llama/llama-4-scout-17b-16e-instruct` |
| **Scam News Feed** | RapidAPI Cyber Security News |
| **State Management** | Provider (`ThemeProvider`) + `StreamBuilder` |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.x`
- Dart SDK `^3.11.0`
- A Firebase project (see setup below)
- A [Groq API key](https://console.groq.com)
- A [RapidAPI key](https://rapidapi.com) with access to **Cyber Security News**
- A [Cloudinary](https://cloudinary.com) account

### 1. Clone the repository

```bash
git clone https://github.com/NonDedicatedDevs/civicshield.git
cd civicshield
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Google + Email/Password), **Firestore**, **Storage**, and **Cloud Messaging**
3. Run FlutterFire CLI to generate `firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Set up API keys

> ⚠️ **Security Note:** API keys are currently hardcoded for hackathon purposes. Before deploying to production, move all secrets to environment variables or a secrets manager (e.g., `--dart-define`, `.env` with `flutter_dotenv`, or Firebase Remote Config).

Update the following files with your keys:

| File | Variable |
|---|---|
| `lib/pages/home.dart` (line 77) | Groq API Key |
| `lib/services/cybernews.dart` (line 13) | RapidAPI Key |

Also update Cloudinary settings in `lib/services/cloudinary_service.dart`:
```dart
cloudName: 'YOUR_CLOUD_NAME',
uploadPreset: 'YOUR_UPLOAD_PRESET',
```

### 5. Run the app

```bash
# Android / iOS
flutter run

# Web
flutter run -d chrome

# Windows / macOS / Linux
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

---

## 🏗️ Architecture

```
civicshield/
├── lib/
│   ├── main.dart                    # App entry point; Firebase init, auth routing
│   ├── firebase_options.dart        # FlutterFire CLI-generated config
│   ├── pages/
│   │   ├── authenticate.dart        # Login (Google + Email)
│   │   ├── email_sign_in.dart       # Email sign-in form
│   │   ├── email_sign_up.dart       # Email registration form
│   │   ├── home.dart                # Main shell (IndexedStack + BottomNav)
│   │   ├── profile.dart             # Profile, settings, fact-check history
│   │   ├── fact_check_chat.dart     # AI fact-checking chat UI
│   │   ├── search_page.dart         # Policy/news search
│   │   ├── scams_page.dart          # Scam alerts list
│   │   └── scam_alert.dart          # Scam alert detail page
│   ├── services/
│   │   ├── fact_check_service.dart  # Groq API integration
│   │   ├── cybernews.dart           # RapidAPI scam feed + fallback data
│   │   ├── cloudinary_service.dart  # Image upload
│   │   └── image_upload_service.dart
│   ├── models/
│   │   ├── fact_result.dart         # FactResult model
│   │   └── scamalert.dart           # ScamAlert model
│   └── Widgets/
│       └── scamalertsection.dart    # Scam alert card widget
```

### App Startup Flow

```
main()
  └─► Firebase.initializeApp()
        └─► runApp (ThemeProvider + MyApp)
              └─► StreamBuilder on authStateChanges
                    ├─ No user  ──► AuthenticatePage
                    └─ User     ──► HomePage
```

> **Note:** The app force-signs out on every cold start (`main.dart` line 17). This was added intentionally for the hackathon demo. Remove or toggle this off for persistent user sessions.

### Firestore Data Model

```
/users/{uid}
  - fullName: String
  - email: String
  - ministry: String
  - role: String

/fact_checks/{docId}
  - userId: String
  - queryText: String
  - imageUrl: String?
  - timestamp: Timestamp
  - result:
      - status: String               # "True" | "False" | "Misleading"
      - accuracy_percentage: int
      - easy_explanation: String
      - references: List<String>
      - is_ai_generated: bool
      - authenticity_reason: String
```

---

## 🌐 Platform Support

| Platform | Status |
|---|---|
| Android | ✅ Supported (`minSdk` 21) |
| iOS | ✅ Supported |
| Web | ✅ Supported |
| Windows | ✅ Supported |
| macOS | ✅ Supported |
| Linux | ⚠️ Folder exists; Firebase not configured |

---

## ⚠️ Known Limitations

- **API keys are hardcoded** — must be moved to secrets management before production use
- **Policy data is static mock data** — not yet pulled from a real government API
- Activity stats "Searches" and "Saved" are hardcoded to `0`; only "Chats" is live from Firestore
- Force sign-out on startup means no persistent login session

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 👥 Team

**NonDedicatedDevs** — MEGAHACK-2026

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
  Made with ❤️ for Indian citizens · MEGAHACK-2026
</div>
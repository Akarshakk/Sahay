# Sahay - Crisis Response Platform 🚨

**Sahay** (meaning "Help" in Hindi) is a next-generation decentralized disaster management and crisis response platform. It connects Citizens, Verified Volunteers, and Authorities in real-time to ensure rapid response during emergencies.

![Sahay App Banner](https://via.placeholder.com/800x200?text=Sahay+Crisis+Response+Platform)

## 🌟 Key Features

### 1. 🆘 Citizen SOS & Reporting
- **One-Tap SOS**: instantly alerts nearby volunteers and authorities with live location.
- **Incident Reporting**: Report Fire, Accident, Medical, or Disaster events with photos/video.
- **Offline Mode**: Works even with low connectivity by queuing reports.

### 2. 🤝 Volunteer Network
- **Verification System**: Volunteers verify incidents ("True/False") to prevent fake news and spam.
- **Resource Management**: Track and manage inventory (Food packets, Medical kits) with real-time stock updates.
- **Task Dashboard**: Gamified task list for volunteers initiated by authorities.

### 3. 🛡️ Authority Command Center
- **Live Heatmaps**: Visualise crisis zones and incident density.
- **Resource Dispatch**: One-click dispatch of police/fire/medical units to verified locations.
- **Broadcast Alerts**: Send push notifications to specific geographic zones.
- **Analytics**: Real-time stats on response times and resource utilization.

---

## 🏗️ Technical Architecture

This project is built using **Flutter** with a **Feature-First Clean Architecture**.

- **State Management**: [Riverpod](https://riverpod.dev/) (2.x with Code Generation)
- **UI Framework**: Material 3 Design System
- **Animation**: `flutter_animate` for smooth interactions
- **Location**: `geolocator` and `geocoding` with smart fallback logic for demos
- **Navigation**: Standard Navigator 2.0 pattern with Role-Based Routing

### Folder Structure
```
lib/
├── core/               # Shared utilities, models, themes
├── features/           # Feature modules
│   ├── auth/           # Login, Registration, Role logic
│   ├── home/           # Main Dashboard (Adaptive UI)
│   ├── incidents/      # Reporting & Feed
│   ├── volunteer/      # Verification & Resources
│   └── authority/      # Command Center & Analytics
└── main.dart           # App Entry Point & ProviderScope
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Stable)
- Dart SDK
- Chrome (for Web debugging) or Android Emulator

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/sahay.git
   cd Sahay
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   # Run on Chrome (Recommended for Demo)
   flutter run -d chrome
   ```

### 🔐 Test Credentials (Demo)

| Role | Phone Number | OTP | Usage |
|------|--------------|-----|-------|
| 👤 **Citizen** | `1111111111` | 1234 | Reporting incidents, SOS |
| ⛑️ **Volunteer** | `2222222222` | 1234 | Verifying incidents, Managing resources |
| 🛡️ **Authority** | `3333333333` | 1234 | Dispatching, Heatmaps, Broadcasts |

---

## 💡 Smart Features
- **Smart Geocoding**: Automatically falls back to a simulated "Sahay Control HQ" address if GPS reverse-geocoding fails during demos.
- **Role Adaptation**: The Home Screen automatically adapts its UI (Quick Actions, Banners, Drawer) based on the logged-in user's role.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.

*Built for Code-A-Thon Sahay-AI 2026*

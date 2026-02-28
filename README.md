# 🆘 Sahay - Crisis Response Platform

**Sahay** (Hindi for "Help") is a comprehensive crisis response platform that connects citizens, volunteers, and authorities during emergencies.

![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue)
![Node.js](https://img.shields.io/badge/Node.js-18+-green)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange)

--

## ✨ Features

### 👤 For Citizens
- **🆘 One-Tap SOS** - Instant emergency alerts with location
- **📍 Community Feed** - Report and view incidents within 10km
- **📱 Emergency Contacts** - Quick-dial emergency services (100, 101, 102, 108)
- **🗺️ Live Location Sharing** - Share location with responders

### 🙋 For Volunteers
- **✅ Task Management** - Accept and complete nearby tasks
- **🔍 Verification System** - Verify community-reported incidents
- **📊 Resource Tracking** - Toggle availability status

### 🛡️ For Authorities
- **📡 Command Center** - Real-time incident monitoring
- **🗺️ Heatmap View** - Visualize incident density
- **📢 Broadcast Alerts** - Send emergency notifications
- **📈 Analytics Dashboard** - Track response metrics

--

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.19+
- Node.js 18+
- Firebase account (free tier works)

### 1️⃣ Clone & Setup
```bash
git clone <repository-url>
cd Sahay
```

### 2️⃣ Start Backend
```bash
cd backend
npm install
npm start
```
Backend runs on `http://localhost:3000`

### 3️⃣ Start Flutter App
```bash
# In a new terminal
cd Sahay
flutter pub get
flutter run
```

--

## 📁 Project Structure

```
Sahay/
├── lib/                    # Flutter App
│   ├── core/               # Shared utilities, themes, services
│   │   ├── theme/          # App colors & styling
│   │   ├── services/       # API, location, offline
│   │   ├── providers/      # State management (Riverpod)
│   │   └── models/         # Data models
│   └── features/           # Feature modules
│       ├── auth/           # Login, splash screen
│       ├── home/           # Main dashboard, role-based UI
│       ├── feed/           # Community feed, posts
│       ├── profile/        # User profile
│       ├── incidents/      # Incident reporting
│       ├── volunteer/      # Volunteer dashboard
│       └── authority/      # Authority dashboard
├── backend/                # NestJS Backend
│   ├── src/
│   │   ├── modules/        # Feature modules (auth, feed, incidents)
│   │   └── firebase/       # Firebase Firestore integration
│   └── .env                # Environment variables
├── test/                   # Unit tests
└── web/                    # Web build assets
```

--

## 🔧 Configuration

### Backend Environment (`.env`)
```env
PORT=3000
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_CLIENT_EMAIL=your-service-account-email
FIREBASE_PRIVATE_KEY="your-private-key"
DEFAULT_SEARCH_RADIUS_METERS=10000
```

---

## 📱 User Roles

| Role | Access Code | Features |
|------|-------------|----------|
| Citizen | Any phone number | SOS, Feed, Report incidents |
| Volunteer | Use "volunteer" or "vol" in name | Tasks, Verification, Resource toggle |
| Authority | Use "authority" in name | Command center, Heatmap, Broadcast |

---

## 🛠️ Tech Stack

- **Frontend**: Flutter, Riverpod, Material Design 3
- **Backend**: NestJS, TypeScript, Firebase Firestore
- **Database**: Firebase Firestore (NoSQL)
- **Auth**: JWT tokens, phone-based login (demo mode)

---

## 📞 Emergency Numbers (India)

| Service | Number |
|---------|--------|
| Police | 100 |
| Fire | 101 |
| Ambulance | 102 |
| Disaster Response | 108 |
| National Emergency | 112 |

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 📄 License

MIT License - feel free to use for hackathons and projects!

---

**Built with ❤️ for crisis response and community safety by Team Code4Change**

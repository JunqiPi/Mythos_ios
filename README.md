# Mythos Mobile App (React Native + Expo)

A cross-platform mobile application for the Mythos web novel platform, built with React Native and Expo.

## 🚀 Quick Start

### Prerequisites

- Node.js 20.19.4+ (currently using 20.19.0, may have compatibility warnings)
- npm or yarn
- Expo Go app on your mobile device (for testing)
- iOS Simulator (Mac only) or Android Emulator

### Installation

```bash
# Install dependencies
npm install

# Start the development server
npm start

# Run on iOS (Mac only)
npm run ios

# Run on Android
npm run android

# Run on web
npm run web
```

## 📁 Project Structure

```
Mythos_mobile/
├── src/
│   ├── components/     # Reusable UI components
│   ├── screens/        # App screens/pages
│   ├── navigation/     # Navigation configuration
│   ├── services/       # API services
│   ├── contexts/       # React Context providers
│   ├── hooks/          # Custom React hooks
│   ├── types/          # TypeScript type definitions
│   ├── utils/          # Utility functions
│   └── config/         # App configuration
├── assets/             # Images, fonts, etc.
├── App.tsx             # Main app component
└── package.json
```

## 🔧 Configuration

### API Configuration

Update the API endpoint in `src/config/api.config.ts`:

- **iOS Simulator**: `http://localhost:8000/api`
- **Android Emulator**: `http://10.0.2.2:8000/api`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.x:8000/api`)

### Environment Setup

The app connects to the Mythos backend API running at `http://localhost:8000/api` by default.

Make sure the backend is running:

```bash
cd ../Mythos-api
docker-compose up -d
```

## 🛠️ Development

### Key Technologies

- **React Native**: Cross-platform mobile framework
- **Expo**: Development platform for React Native
- **TypeScript**: Type-safe JavaScript
- **React Navigation**: Navigation library
- **Axios**: HTTP client for API requests
- **Expo Secure Store**: Secure token storage

### Services

- `api.service.ts` - Base API client with authentication
- `auth.service.ts` - Authentication (login, register, logout)
- `book.service.ts` - Book-related API calls

### Adding New Features

1. Create screen components in `src/screens/`
2. Add API service methods in `src/services/`
3. Define TypeScript types in `src/types/`
4. Update navigation in `src/navigation/`

## 📱 Testing on Devices

### Using Expo Go

1. Install Expo Go on your mobile device
2. Run `npm start` in the project directory
3. Scan the QR code with:
   - iOS: Camera app
   - Android: Expo Go app

### Using Simulators/Emulators

```bash
# iOS Simulator (Mac only)
npm run ios

# Android Emulator
npm run android
```

## 🔒 Authentication

The app uses JWT token authentication stored securely in Expo Secure Store:

1. User logs in → Receives JWT token
2. Token stored in Expo Secure Store
3. Token automatically added to all API requests
4. Auto-logout on token expiration

## 🐛 Troubleshooting

### Connection Issues

If you can't connect to the backend:

1. **Check backend is running**: `docker-compose ps` in Mythos-api folder
2. **Update API URL**: Check `src/config/api.config.ts`
3. **For Android Emulator**: Use `10.0.2.2` instead of `localhost`
4. **For Physical Device**: Use your computer's IP address

### Node Version Warnings

The app may show warnings about Node.js version (requires 20.19.4+). These are typically non-critical but you can update Node.js if needed.

### Clear Cache

```bash
npm start -- --clear
```

## 📚 Related Documentation

- [Expo Documentation](https://docs.expo.dev/)
- [React Native Documentation](https://reactnative.dev/)
- [React Navigation](https://reactnavigation.org/)
- Backend API: See `/Mythos-api/docs/API.md`

## 🤝 Contributing

Follow the same development guidelines as the main project (see `/CLAUDE.md`).

## 📄 License

MIT

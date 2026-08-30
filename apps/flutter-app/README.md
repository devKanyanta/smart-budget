# Smart Budget ZM - Flutter App

Android-first mobile budgeting application for the Zambian market.

## Setup

```bash
flutter pub get
flutter run
```

## Architecture

- **lib/core/** — Services (API, Auth, Storage), Providers (state management)
- **lib/data/** — Data models and repositories
- **lib/presentation/** — UI screens organized by feature

## Features

- 📊 Dashboard with financial summary
- 💰 Transaction tracking (manual + mobile money sync)
- 📈 Budget management with progress tracking
- 🎯 Savings goals with predictions
- 📉 Analytics with charts
- 📱 Offline support (Hive)
- 🔔 Push notifications
- 🔐 Secure JWT authentication

## Configuration

Set the API base URL in `lib/core/services/api_service.dart`:
- Android emulator: `http://10.0.2.2:3000/api/v1`
- Physical device: `http://<your-ip>:3000/api/v1`

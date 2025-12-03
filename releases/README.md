# Releases

This directory contains pre-built APK files for testing and distribution.

## Latest Release

**Version 1.0.0** - `streakoo-v1.0.0.apk` (63.3MB)

### Installation Instructions

1. Download the APK file to your Android device
2. Enable "Install from Unknown Sources" in your device settings
3. Tap the downloaded APK file to install
4. Follow the on-screen instructions

### Requirements

- Android 5.0 (API level 21) or higher
- Approximately 100MB of free storage space

### First Time Setup

After installation:

1. Create an account or sign in
2. Complete the onboarding process
3. Set up your environment file with API keys (see main README.md)
4. Start tracking your habits!

### Note for Developers

To build your own APK from source:

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

# Releases

This directory contains pre-built APK files for testing and distribution.

## Latest Release

**Version 1.0.0** - `streakoo-v1.0.0.apk` (61MB)  
**Updated**: December 4, 2025

### What's New in This Build

- 🎨 **Enhanced Widget UI** - Redesigned Android home screen widget with streak badges
- 🎉 **Celebration Animations** - Confetti effects for habit completions and level-ups
- 🏥 **Health Coach V2** - Improved health coaching with personalized challenges
- 💫 **Smooth Animations** - New page transitions and animated widgets
- 🍎 **macOS Support** - Google Sign-In now works on macOS
- ☁️ **Cloud Sync Improvements** - Better real-time data synchronization

### Installation Instructions

1. Download the APK file to your Android device
2. Enable "Install from Unknown Sources" in your device settings
3. Tap the downloaded APK file to install
4. Follow the on-screen instructions

### Requirements

- Android 5.0 (API level 21) or higher
- Approximately 120MB of free storage space
- Internet connection for cloud sync and AI features

### First Time Setup

After installation:

1. Create an account or sign in with Google
2. Complete the onboarding process
3. Connect Health Connect for automatic activity tracking (optional)
4. Start tracking your habits!

### Note for Developers

To build your own APK from source:

```bash
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

# Changelog

All notable changes to Streakoo are documented here.

## [1.1.0] - 2025-12-05

### ✨ New Features
- **Spectacular Level-Up Animation**: Pulsing glow, rotating rings, floating particles, and confetti bursts
- **AI Response Animations**: Typing indicators, shimmer loading states, and animated insight cards
- **Dynamic Home Screen Widget**: Auto-updates with motivational messages and progress data

### 🎨 Design Improvements
- Premium dark gradient widget background
- Animated AI coach "thinking" dots
- Enhanced Coach Message Bubble with fade-in animations
- Improved widget streak badge styling

### 🐛 Bug Fixes
- Fixed blank home screen widget by adding initialization on app startup
- Fixed widget data not updating when habits change
- Resolved 50+ linter warnings (deprecated APIs, async context issues)

### 🔧 Technical
- Added `HomeWidgetService.initialize()` for proper widget setup
- Widget data now syncs on app launch via `AppState.loadPreferences()`
- Dynamic motivational messages based on habit progress

---

## [1.0.0] - Initial Release

### Features
- Gamified habit tracking with XP and levels
- AI Coach powered by Groq (Llama models)
- Real-time cloud sync with Supabase
- Health Connect / Apple Health integration
- Smart reminder notifications
- Android home screen widget
- Daily briefs and weekly reports

# Streakoo 🚀
https://bit.ly/4cAoeNc
**The Ultimate AI-Powered Habit Tracker with Gamification**

Streakoo helps you build life-changing habits through XP, streaks, AI coaching, and global competition. Track your progress, compete with friends, and celebrate your wins with Spotify Wrapped-style yearly reviews!

## 🏆 Agents Intensive - Capstone Project

This project is submitted for the Google Agents Intensive Capstone Project.

**License**: CC-BY-SA 4.0 (See [LICENSE](LICENSE))

---

## ✨ What's New in v2.2.0

### 🐾 Smarter Pet Evolution
- **Granular Progress**: Evolution bar now reflects exact XP progress - watch your pet grow with every task!
- **Smooth Updates**: No more waiting for level-ups to see progress.

### 🤝 Social Connection Focus
- **Connect with Friends**: "My Teams" redesigned to emphasize finding accountability buddies.
- **Updated Messaging**: Focus on social connection rather than team creation.
- **New Emoji**: Handshake emoji 🤝 for connection theme.

### 🏆 Achievement Showcase
- **Earned First**: Your earned badges now appear first in the achievements modal.
- **Fixed Unlocking**: Achievement detection now properly matches your streak data.

### ⚡ Performance
- **Lightning Start**: App launches instantly - heavy data loads in background.
- **Optimized Startup**: Critical path reduced to ~100ms.

### 🎯 UI Polish
- **Global Ranking Clarity**: Shows "Top X% by Consistency" based on your completion rate.
- **Focus Tasks Save Button**: Now visible in light theme.
- **What's New Popup**: See new features on every update!

### 📦 Release APK
Download the latest APK from the [Releases](https://github.com/policeakshithreddy/Streakoo/releases) page.

---

## 📱 Core Features

### Gamification
*   **XP System**: Earn points for every habit completion
*   **Level Up**: Progress through 50+ levels
*   **Avatars**: Unlock new avatars as you level up
*   **Achievements**: 10+ badges with rarity tiers
*   **Streak Tracking**: Build and maintain daily streaks

### AI Coach (Powered by Groq + Llama)
*   **Personalized Advice**: Health and habit guidance
*   **Daily Briefs**: Morning motivation and insights
*   **Weekly Reports**: Pattern analysis and recommendations
*   **Chat Interface**: Ask anything about your habits
*   **Smart Suggestions**: Habit recommendations based on your data

### Health & Wellness
*   **Activity Rings**: Apple-style activity visualization
*   **Health Integration**: Google Fit / Apple Health
*   **Auto-tracking**: Steps, sleep, calories, heart rate
*   **Health Challenges**: AI-generated personalized challenges
*   **Progress Dashboard**: Comprehensive health metrics

### Social & Competition
*   **Leaderboard**: Global and weekly rankings
*   **Privacy Controls**: Choose visibility
*   **Share Achievements**: Social media integration
*   **Year in Review**: Shareable annual summary

---

## 🛠️ Tech Stack

*   **Frontend**: Flutter 3.x (Dart)
*   **Backend**: Supabase (PostgreSQL, Auth, Realtime, Storage)
*   **AI**: Groq API (Llama 3.3 70B & Mixtral 8x7B)
*   **State Management**: Provider
*   **Animations**: flutter_animate
*   **Platform**: Android, iOS, macOS

---

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (Latest Stable)
*   Dart SDK 3.0+
*   Supabase Account (Free tier works)
*   Groq API Key ([Get free key](https://console.groq.com))
*   Google OAuth Client IDs

### 1. Clone & Install

```bash
git clone <repository-url>
cd streakoo
flutter pub get
```

### 2. Environment Setup

**Create your environment file:**

```bash
cp lib/config/env.example.dart lib/config/env.dart
```

**Edit `lib/config/env.dart` with your credentials:**

```dart
class Env {
  // Supabase (Get from: https://app.supabase.com/project/_/settings/api)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Google OAuth (Get from: https://console.cloud.google.com/)
  static const String googleWebClientId = 'YOUR_WEB_CLIENT_ID';
  static const String googleIosClientId = 'YOUR_IOS_CLIENT_ID';
  
  // Groq AI (Get from: https://console.groq.com/keys)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY';
}
```

### 3. Supabase Database Setup

Run this SQL in your Supabase SQL Editor:

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- User Profiles
create table public.user_profiles (
  user_id uuid references auth.users not null primary key,
  username text,
  age int,
  created_at timestamp with time zone default now() not null
);

-- Habits Table
create table public.habits (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  description text,
  emoji text,
  frequency text[],
  created_at timestamp with time zone default now() not null,
  is_focus_task boolean default false,
  focus_task_priority int default 0
);

-- User Levels
create table public.user_levels (
  user_id uuid references auth.users not null primary key,
  level int default 1,
  current_xp int default 0,
  total_xp int default 0,
  xp_to_next_level int default 100,
  updated_at timestamp with time zone default now() not null
);

-- Leaderboard Scores
create table public.user_scores (
  user_id uuid references auth.users(id) on delete cascade primary key,
  username text not null,
  total_score integer default 0,
  current_week_score integer default 0,
  week_start_date date,
  last_updated timestamp with time zone default now()
);

-- Enable Row Level Security
alter table public.user_profiles enable row level security;
alter table public.habits enable row level security;
alter table public.user_levels enable row level security;
alter table public.user_scores enable row level security;

-- RLS Policies
create policy "Users can view own profile" on user_profiles for select using (auth.uid() = user_id);
create policy "Users can update own profile" on user_profiles for update using (auth.uid() = user_id);
create policy "Users can insert own profile" on user_profiles for insert with check (auth.uid() = user_id);

create policy "Users can view own habits" on habits for select using (auth.uid() = user_id);
create policy "Users can manage own habits" on habits for all using (auth.uid() = user_id);

create policy "Users can view own level" on user_levels for select using (auth.uid() = user_id);
create policy "Users can manage own level" on user_levels for all using (auth.uid() = user_id);

create policy "Users can read all scores" on user_scores for select using (true);
create policy "Users can update own score" on user_scores for all using (auth.uid() = user_id);

-- Leaderboard Indexes
create index idx_user_scores_total on user_scores(total_score desc);
create index idx_user_scores_weekly on user_scores(current_week_score desc, week_start_date desc);
```

### 4. Enable Authentication

In Supabase Dashboard → **Authentication → Providers**:
- ✅ Enable **Email/Password**
- ✅ Enable **Google Sign-In** (add your OAuth credentials)
- ✅ Turn on **Email Confirmation** for production

### 5. Run the App

```bash
# Run on connected device/emulator
flutter run

# Or specify platform
flutter run -d macos
flutter run -d ios
flutter run -d android
```

---

## 📱 How to Use

1. **Sign Up**: Create an account with email/Google
2. **Complete Onboarding**: Set up your profile
3. **Add Habits**: Create your first habits with emojis
4. **Daily Tracking**: Mark habits as complete to earn XP
5. **Build Streaks**: Maintain daily streaks for bonuses
6. **AI Coach**: Get personalized insights and advice
7. **Compete**: Join the leaderboard (opt-in)
8. **Year in Review**: View your annual stats (Stats tab)

---

## 🗺️ Roadmap

### ✅ Recently Completed (v2.2.0)

#### Social Features
- [x] Accountability partners system
- [x] Teams with shared habit challenges
- [x] Partner streak comparison
- [x] Competition notifications

#### Gamification Enhancements
- [x] Streak freeze tokens
- [x] Pet evolution with XP progress
- [x] Achievement badges showcase
- [x] Level-up celebrations

#### UX Improvements
- [x] Celebration animations (confetti)
- [x] What's New popup on updates
- [x] Haptic feedback throughout app
- [x] Fast app startup

### 🚀 Next Release (v2.3.0) - Planned

#### Social Features
- [ ] Community feed for achievements
- [ ] Comment and encourage friends
- [ ] Share habit templates

#### Engagement
- [ ] Daily/weekly challenges system
- [ ] Morning motivation / evening reflection
- [ ] XP multipliers (weekends, perfect weeks)
- [ ] Daily login rewards

### 📅 Future Features

#### Engagement
- [ ] Daily/weekly challenges system
- [ ] Referral program with rewards
- [ ] User-created habit templates marketplace
- [ ] Progress predictions with ML
- [ ] Personalized habit recommendations

#### Premium Features (Monetization)
- [ ] Unlimited streak freezes
- [ ] Advanced analytics
- [ ] Custom themes
- [ ] Priority AI insights
- [ ] Ad-free experience

#### Platform Expansion
- [ ] Web app (Progressive Web App)
- [ ] Apple Watch companion app
- [ ] Wear OS support
- [ ] Desktop widgets

---

## 🎯 Feature Highlights

### For Users Who Love Data
- 📊 Comprehensive analytics dashboard
- 📈 Trend analysis and predictions
- 🔥 Streak tracking with visual flames
- 📅 Habit heatmaps
- 🎉 Year in Review (Spotify Wrapped style)

### For Competitive Users
- 🏆 Global leaderboard
- 🥇 Weekly rankings reset
- 📊 Live score updates
- 🎖️ Achievement badges
- 🤝 Friend challenges (coming soon)

### For Privacy-Conscious Users
- 🔒 Privacy-first leaderboard (opt-in)
- 💾 Local-first data storage
- ☁️ Encrypted cloud sync
- 🚫 No data selling
- 👤 Guest mode supported

---

## 🤝 Contributing

This is a capstone project, but suggestions and bug reports are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

**CC-BY-SA 4.0** - Attribution-ShareAlike 4.0 International

You are free to:
- ✅ Share and adapt
- ✅ Commercial use allowed

Under these terms:
- 📝 Attribution required
- 🔄 ShareAlike (derivatives under same license)

See [LICENSE](LICENSE) for full details.

---

## 🙏 Acknowledgments

- **Google Agents Intensive** for the capstone opportunity
- **Supabase** for amazing backend infrastructure
- **Groq** for lightning-fast AI inference
- **Flutter** team for the incredible framework

---

## 📧 Contact

Have questions or feedback? Open an issue!

**Built with ❤️ using Flutter & AI**

# Streakoo 🚀

**The Ultimate AI-Powered Habit Tracker with Gamification**

Streakoo helps you build life-changing habits through XP, streaks, AI coaching, and global competition. Track your progress, compete with friends, and celebrate your wins with Spotify Wrapped-style yearly reviews!

## 🏆 Agents Intensive - Capstone Project

This project is submitted for the Google Agents Intensive Capstone Project.

**License**: CC-BY-SA 4.0 (See [LICENSE](LICENSE))

---

## ✨ What's New in v2.1.0

### 🎉 Year in Review (Spotify Wrapped Style!)
- Beautiful animated slides showcasing your entire year
- Total habits created, completions, streaks, and XP earned
- Top performing habits and categories
- Streak evolution timeline
- Achievement highlights with celebrations
- **Share to social media** with one tap

### 🏆 Global Leaderboard
- Compete with users worldwide
- Weekly and all-time rankings
- **Privacy controls** - stay private or go public
- Real-time score updates based on:
  - Daily completions (10 pts each)
  - Longest streaks (5 pts per day)
  - Consistency rate (completion %)
  - Total XP earned

### 🧠 Smart Habit Insights
- AI analyzes your completion patterns
- Identifies struggling habits
- Sends personalized insights as notifications
- Trend analysis and predictions
- Best/worst performing days

### 🔔 Smart Notifications
- **Predictive streak warnings** at 6 PM
- Milestone celebrations (7, 30, 100 days)
- Daily brief every morning
- Perfect day achievements
- Focus task reminders

### 🔥 Streak Flames
- Animated fire visualizations
- Flame intensity grows with streak length
- Visual motivation on home screen
- Celebrate streak milestones

### ☁️ Smart Cross-Device Sync
- Conflict resolution for streaks
- User confirmation dialogs
- Seamless multi-device experience
- Automatic backup to cloud

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

### 🚀 Next Release (v2.2.0) - Planned

#### Social Features
- [ ] Friend system with challenges
- [ ] Accountability partners
- [ ] Community feed for achievements
- [ ] Comment and encourage friends
- [ ] Share habit templates

#### Gamification Enhancements
- [ ] Streak freeze tokens (1 per week)
- [ ] 20+ new achievement badges
- [ ] Level-based feature unlocks
- [ ] XP multipliers (weekends, perfect weeks)
- [ ] Daily login rewards

#### UX Improvements
- [ ] Celebration animations (confetti, fireworks)
- [ ] Morning motivation / evening reflection
- [ ] Habit streaks dashboard with heatmap
- [ ] Undo feature for accidental completions
- [ ] Haptic feedback throughout app

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

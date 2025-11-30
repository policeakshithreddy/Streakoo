# Streakoo 🚀

Streakoo is a gamified habit tracker built with Flutter, designed to help users build and maintain positive habits through streaks, levels, and AI-powered coaching.

## 🏆 Agents Intensive - Capstone Project

This project is submitted for the Google Agents Intensive Capstone Project.

**License**: CC-BY-SA 4.0 (See [LICENSE](LICENSE))

## ✨ Features

*   **Gamification**: Earn XP, level up, and unlock avatars by completing habits.
*   **AI Coach**: Personalized health and habit advice powered by **Google Gemini**.
*   **Real-Time Sync**: "Every single bit" of data is instantly synced to the cloud using **Supabase**.
*   **Health Integration**: Connects with Google Fit / Health Connect for automatic habit tracking (steps, sleep, etc.).
*   **Smart Reminders**: Local notifications to keep you on track.
*   **Offline Support**: Works offline and syncs when back online.

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Supabase (PostgreSQL, Auth, Realtime)
*   **AI**: Google Gemini API (via `google_generative_ai` package)
*   **State Management**: Provider

## 🚀 Getting Started

Follow these instructions to set up the project locally.

### Prerequisites

*   Flutter SDK (Latest Stable)
*   Dart SDK
*   A Supabase Account (Free Tier is fine)
*   A Google Cloud Project with Gemini API enabled (AI Studio)

### 1. Clone the Repository

```bash
git clone <repository-url>
cd streakoo
flutter pub get
```

### 2. Supabase Setup

1.  Create a new project on [Supabase](https://supabase.com/).
2.  Go to **Project Settings > API** and copy your `URL` and `anon` Key.
3.  **Database Schema**: Run the following SQL in the Supabase SQL Editor to set up the required tables:

```sql
-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- User Profiles
create table public.user_profiles (
  user_id uuid references auth.users not null primary key,
  username text,
  age int,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Habits
create table public.habits (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  description text,
  emoji text,
  frequency list, -- You might need to adjust based on your exact schema or use JSONB
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  -- Add other fields as per lib/models/habit.dart
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
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.user_profiles enable row level security;
alter table public.habits enable row level security;
alter table public.user_levels enable row level security;

-- Create Policies (Simplified for demo)
create policy "Users can view their own profile" on public.user_profiles for select using (auth.uid() = user_id);
create policy "Users can update their own profile" on public.user_profiles for update using (auth.uid() = user_id);
create policy "Users can insert their own profile" on public.user_profiles for insert with check (auth.uid() = user_id);

create policy "Users can view their own habits" on public.habits for select using (auth.uid() = user_id);
create policy "Users can insert their own habits" on public.habits for insert with check (auth.uid() = user_id);
create policy "Users can update their own habits" on public.habits for update using (auth.uid() = user_id);
create policy "Users can delete their own habits" on public.habits for delete using (auth.uid() = user_id);

create policy "Users can view their own level" on public.user_levels for select using (auth.uid() = user_id);
create policy "Users can insert their own level" on public.user_levels for insert with check (auth.uid() = user_id);
create policy "Users can update their own level" on public.user_levels for update using (auth.uid() = user_id);
```

4.  **Authentication**: Enable Email/Password and Google Sign-In in **Authentication > Providers**.
    *   **IMPORTANT**: Enable "Confirm email" in Email provider settings to test the verification flow.

### 3. Environment Configuration

Create a `.env` file in the root directory (or update `lib/services/supabase_service.dart` / `lib/config.dart` if hardcoded) with your keys:

```dart
// In lib/main.dart or a config file
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const geminiApiKey = 'YOUR_GEMINI_API_KEY';
```

*(Note: Ensure you don't commit your actual keys if using a public repo. For this submission, keys might be required in a private note or configured by the judges).*

### 4. Run the App

```bash
flutter run
```

## 📱 How to Use

1.  **Sign Up**: Create an account. You'll need to verify your email (check your spam folder or Supabase logs).
2.  **Onboarding**: Complete the initial profile setup.
3.  **Add Habits**: Create new habits, set emojis, and frequencies.
4.  **Complete Habits**: Mark habits as done to earn XP and maintain streaks.
5.  **AI Coach**: Chat with the AI Coach for advice (unlocks after completing your first habit!).
6.  **Sync**: Your data is automatically saved to the cloud. Try logging in from another device!

## 📄 License

This project is licensed under the **CC-BY-SA 4.0** License - see the [LICENSE](LICENSE) file for details.

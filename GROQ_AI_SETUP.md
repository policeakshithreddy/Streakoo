# 🤖 Groq AI Integration Guide

## 📍 Where to Paste Your API Key

**File Location:** `lib/config/app_config.dart`

**Line to Edit:** Line 3

```dart
static const String groqApiKey = 'YOUR_GROQ_API_KEY'; // 👈 PASTE YOUR API KEY HERE
```

Replace `'YOUR_GROQ_API_KEY_HERE'` with your actual Groq API key.

---

## 🔑 Getting Your Groq API Key

1. **Visit:** https://console.groq.com/
2. **Sign Up / Log In**
3. **Generate API Key:**
   - Go to "API Keys" section
   - Click "Create API Key"
   - Copy the key (you won't see it again!)
4. **Paste in `app_config.dart`**

---

## ✨ What the AI Powers

Once you add your API key, Streakoo will use Groq's language models for:

### 1. **Smart Habit Suggestions** 🎯
- Personalized based on your goals
- Adapts to your current mood
- Avoids duplicating existing habits
- Context-aware recommendations

### 2. **AI Coaching Messages** 💬
- Personalized encouragement
- References your actual progress
- Adapts tone to your mood
- Genuine, non-generic messages

### 3. **Mood Pattern Analysis** 📊
- Insights from your mood history
- Actionable recommendations
- Mental wellness guidance

### 4. **Motivational Content** ✨
- Context-aware quotes
- Milestone celebration stories
- Dynamic motivational messages

### 5. **Habit Stories** 📖
- AI-generated celebration stories at milestones
- Personalized narrative of your journey
- Emotional and inspiring

---

## 🚀 Models Available

Edit in `app_config.dart`:

```dart
static const String groqModel = 'mixtral-8x7b-32768';
```

**Options:**
- `mixtral-8x7b-32768` - **Recommended** (balanced speed & quality)
- `llama-3.3-70b-versatile` - Most powerful (slower but best results)
- `llama-3.1-8b-instant` - Fastest (good for simple tasks)

---

## ⚙️ Configuration Options

In `app_config.dart`, you can customize:

```dart
// Feature flags (enable/disable AI features)
static const bool useAIForHabitSuggestions = true;
static const bool useAIForCoaching = true;
static const bool useAIForMoodAnalysis = true;

// AI behavior
static const double aiTemperature = 0.7;  // 0.0 = focused, 1.0 = creative
static const int maxTokens = 500;         // Max response length
```

---

## 🔄 How It Works

1. **User Action** → Triggers AI request
2. **Groq Service** → Sends prompt to Groq API
3. **Language Model** → Generates personalized response
4. **Display** → Shows in app UI

**Fallback:** If API key is not configured or request fails, the app uses pre-written responses.

---

## 🧪 Testing the Integration

### Test Habit Suggestions
1. Open the app
2. Try to add a new habit
3. AI will suggest personalized habits

### Test Coaching Messages
1. Complete habits
2. Check for AI-generated encouragement
3. Messages adapt to your progress

### Test Mood Analysis
1. Log moods for several days
2. View Stats → Trends tab
3. See AI-powered insights

---

## 🛡️ API Key Security

**⚠️ Important:**
- Never commit your API key to version control
- Add `lib/config/app_config.dart` to `.gitignore` if sharing code
- For production, use environment variables or secure storage

**Better approach for production:**
```dart
// Use flutter_dotenv or similar
static String get groqApiKey => 
    const String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
```

---

## 💰 Groq API Pricing

- **Free Tier:** Very generous limits
- **Fast Inference:** Groq is one of the fastest LLM providers
- **Cost-Effective:** Much cheaper than OpenAI/Anthropic

Check current pricing: https://groq.com/pricing/

---

## 🐛 Troubleshooting

### "API key not configured"
→ Check that you've replaced `'YOUR_GROQ_API_KEY_HERE'` with your actual key

### "API Error 401"
→ Your API key is invalid or expired. Generate a new one.

### "API Error 429"
→ Rate limit exceeded. Wait a moment and try again.

### No AI responses
→ Check console for error messages
→ Verify internet connection
→ Ensure API key is valid

---

## 📝 Example Integration

When you complete all habits for the day, the app will:

1. **Without AI:** Show generic "Great job!"
2. **With AI:** Generate personalized message like:
   > "Wow, you crushed it today! All 5 habits done and your 14-day streak is looking unstoppable. This momentum is going to take you places! 🚀"

---

## 🎯 Next Steps

1. ✅ Get Groq API key
2. ✅ Paste in `lib/config/app_config.dart`
3. ✅ Run the app: `flutter run`
4. ✅ Test AI features
5. ✅ Enjoy personalized AI coaching!

---

## 🤝 Support

- **Groq Docs:** https://docs.groq.com/
- **Groq Discord:** Join for support and updates
- **Issue with integration:** Check console logs for detailed errors

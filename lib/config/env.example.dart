/// Example environment configuration.
/// Copy this file to env.dart and fill in your values,
/// OR use --dart-define flags at build time.
///
/// flutter run \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=your-anon-key \
///   --dart-define=GOOGLE_WEB_CLIENT_ID=your-web-client-id \
///   --dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id \
///   --dart-define=GROQ_API_KEY=your-groq-api-key
class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'YOUR_GOOGLE_WEB_CLIENT_ID',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: 'YOUR_GOOGLE_IOS_CLIENT_ID',
  );

  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_GROQ_API_KEY',
  );
}

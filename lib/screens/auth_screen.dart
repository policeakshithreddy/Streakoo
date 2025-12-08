import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/guest_service.dart';
import 'profile_setup_screen.dart';
import 'question_flow_screen.dart';
import 'data_restoration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showOtpInput = false;
  bool _obscurePassword = true;

  // App theme colors - matching welcome_screen.dart
  static const _primaryOrange = Color(0xFFFFA94A);
  static const _secondaryTeal = Color(0xFF1FD1A5);
  static const _bgDark = Color(0xFF050816);
  static const _bgLight = Color(0xFFFDFBF7);

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCompleteProfile() async {
    debugPrint('🔐 _checkAndCompleteProfile: Starting profile check');

    final supabase = SupabaseService();
    final user = supabase.currentUser;

    // Safety check: Ensure email is verified for email providers
    if (user != null &&
        user.appMetadata['provider'] == 'email' &&
        user.emailConfirmedAt == null) {
      debugPrint('⚠️ Email not verified. Redirecting to OTP input.');
      setState(() {
        _showOtpInput = true;
        _isLoading = false;
      });
      return;
    }

    var profile = await supabase.getUserProfile();

    debugPrint('🔐 Current user ID: ${supabase.currentUser?.id}');
    debugPrint('🔐 Current user email: ${supabase.currentUser?.email}');

    if (mounted && (profile == null || profile['age'] == null)) {
      // No profile or age missing, navigate to setup
      debugPrint(
          '⚠️ Profile missing or incomplete, navigating to ProfileSetupScreen');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
        ),
      );

      // Refresh profile after setup
      profile = await supabase.getUserProfile();
      debugPrint('🔐 Profile after setup: $profile');
    }

    if (mounted && profile != null) {
      final name = profile['username'] ?? 'User';
      final age = profile['age'] ?? 18;

      debugPrint('🔐 Profile complete: name=$name, age=$age');
      debugPrint('🔍 Checking for existing data...');

      // Check for existing data (habits, etc.)
      final hasData = await supabase.hasExistingData();

      debugPrint('🔍 hasExistingData result: $hasData');

      if (mounted) {
        if (hasData) {
          // Restore data flow
          debugPrint(
              '✅ Existing data found - navigating to DataRestorationScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => DataRestorationScreen(userName: name),
            ),
            (route) => false,
          );
        } else {
          // New user flow
          debugPrint('🆕 No existing data - navigating to QuestionFlowScreen');
          _navigateToQuestions(name, age);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final supabase = SupabaseService();
      await supabase.signInWithGoogleNative();

      if (mounted) {
        // For Google users, we skip the age question by setting a default
        // This allows immediate access to the question flow
        final user = supabase.currentUser;
        final profile = await supabase.getUserProfile();

        if (profile == null || profile['age'] == null) {
          final name = user?.userMetadata?['full_name'] ??
              user?.userMetadata?['name'] ??
              'User';

          await supabase.updateUserProfile(
            username: name,
            age: 18, // Default age for Google users to skip prompt
          );
        }

        await _checkAndCompleteProfile();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        // Don't show error for user cancellation
        if (!errorMsg.toLowerCase().contains('cancelled') &&
            !errorMsg.toLowerCase().contains('canceled')) {
          _showError('Google Sign-In failed: $errorMsg');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _navigateToQuestions(String name, int age) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => QuestionFlowScreen(
          displayName: name,
          age: age,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);

    try {
      // Start guest session using GuestService
      final guestService = GuestService();
      await guestService.startGuestSession(name: 'Guest');

      if (mounted) {
        // Navigate to question flow with default guest name
        _navigateToQuestions('Guest', 18);
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to continue as guest: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService();

      if (_isLogin) {
        try {
          // 1. Verify password first
          await supabase.signIn(email: email, password: password);

          // 2. If successful, immediately sign out to enforce OTP
          // This ensures the user MUST verify email to keep the session
          final supabaseClient = Supabase.instance.client;
          await supabaseClient.auth.signOut();

          if (mounted) {
            debugPrint(
                '🔐 Password verified. Starting Step 2: OTP Verification');

            // 3. Send OTP
            await supabase.signInWithOtp(email);

            setState(() {
              _showOtpInput = true;
              _isLoading = false;
            });

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔐 Step 2: Code sent to email. Please verify.'),
                duration: Duration(seconds: 4),
              ),
            );
            return; // Stop here, wait for OTP
          }
        } catch (e) {
          if (e.toString().contains('Email not confirmed')) {
            // User exists but not verified. Switch to OTP view.
            if (mounted) {
              setState(() {
                _showOtpInput = true;
                _isLoading = false;
              });
              _resendCode(); // Auto-resend code
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('⚠️ Email not verified. Sending new code...')),
              );
              return;
            }
          }
          rethrow; // Rethrow other errors
        }
      } else {
        // Sign Up Flow
        try {
          final response =
              await supabase.signUp(email: email, password: password);

          if (mounted) {
            // Check if email confirmation is required
            // If session is null, OR (email provider AND not confirmed), show OTP
            final user = response.user;
            final isEmail = user?.appMetadata['provider'] == 'email';
            final isConfirmed = user?.emailConfirmedAt != null;

            debugPrint('🔐 Signup Debug:');
            debugPrint(
                '   - Session: ${response.session != null ? "Active" : "Null"}');
            debugPrint('   - Provider: ${user?.appMetadata['provider']}');
            debugPrint('   - Email Confirmed At: ${user?.emailConfirmedAt}');
            debugPrint('   - Is Confirmed: $isConfirmed');

            if (response.session != null && (!isEmail || isConfirmed)) {
              debugPrint(
                  '✅ Auto-login allowed (Email is confirmed or not email provider)');
              await _checkAndCompleteProfile();
            } else {
              debugPrint('🛑 Verification required. Showing OTP screen.');
              setState(() {
                _showOtpInput = true;
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Code sent! Check your email.')),
              );
              return;
            }
          }
        } catch (e) {
          if (e.toString().contains('User already registered')) {
            // If user exists, try to sign in or verify
            _showError('User already registered. Try signing in.');
            setState(() => _isLogin = true);
            return;
          }
          rethrow;
        }
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted && !_showOtpInput) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);
    try {
      final supabase = SupabaseService();
      await supabase.resendOtp(
        _emailController.text.trim(),
        _isLogin ? OtpType.email : OtpType.signup,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Code resent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to resend: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showError('Please enter the verification code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService();
      await supabase.verifyOtp(
        email: _emailController.text.trim(),
        token: otp,
        type: _isLogin ? OtpType.email : OtpType.signup,
      );

      if (mounted) {
        await _checkAndCompleteProfile();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('otp_expired') || msg.contains('Token has expired')) {
          _showError('Code expired. Please click "Resend Code".');
        } else {
          _showError('Invalid code. Please try again.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          _showOtpInput ? 'Verify Email' : (_isLogin ? 'Sign In' : 'Sign Up'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient background orbs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryOrange.withValues(alpha: isDark ? 0.2 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _secondaryTeal.withValues(alpha: isDark ? 0.15 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Floating animated icon
                    AnimatedBuilder(
                      animation: _floatController,
                      builder: (context, child) {
                        final floatValue = (_floatController.value - 0.5) * 10;
                        return Transform.translate(
                          offset: Offset(0, floatValue),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isDark ? const Color(0xFF1A1A2E) : Colors.white,
                              isDark
                                  ? const Color(0xFF0F0F1A)
                                  : const Color(0xFFF8F8F8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _primaryOrange.withValues(
                                alpha: isDark ? 0.4 : 0.25),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryOrange.withValues(
                                  alpha: isDark ? 0.2 : 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _showOtpInput
                                ? Icons.mark_email_read_rounded
                                : Icons.cloud_sync_rounded,
                            size: 45,
                            color: _primaryOrange,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1, 1),
                            curve: Curves.easeOutBack,
                            duration: 600.ms,
                          ),
                    ),

                    const SizedBox(height: 32),

                    // Glass card form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : _primaryOrange.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showOtpInput
                            ? _buildOtpForm(
                                theme, isDark, textColor, subtitleColor)
                            : _buildAuthForm(
                                theme, isDark, textColor, subtitleColor),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 350.ms)
                        .slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(
      ThemeData theme, bool isDark, Color textColor, Color? subtitleColor) {
    return Column(
      key: const ValueKey('otp_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Check your email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          'We sent a verification code to ${_emailController.text}',
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Verification Code',
            labelStyle: TextStyle(color: subtitleColor),
            prefixIcon: Icon(Icons.lock_clock_outlined, color: _primaryOrange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: _primaryOrange.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryOrange, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
          ),
          keyboardType: TextInputType.number,
          maxLength: 8,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _isLoading ? null : _verifyOtp,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryOrange, Color(0xFFFFBB6E)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Verify & Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _resendCode,
          child: Text('Resend Code', style: TextStyle(color: _primaryOrange)),
        ),
        TextButton(
          onPressed: () {
            setState(() => _showOtpInput = false);
          },
          child: Text('Back', style: TextStyle(color: subtitleColor)),
        ),
      ],
    );
  }

  Widget _buildAuthForm(
      ThemeData theme, bool isDark, Color textColor, Color? subtitleColor) {
    return Column(
      key: ValueKey(_isLogin ? 'login' : 'signup'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isLogin ? 'Welcome Back!' : 'Create Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to backup and sync your habits'
              : 'Create an account to backup your data',
          style: TextStyle(
            fontSize: 14,
            color: subtitleColor,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 28),
        // Google Sign-In button
        GestureDetector(
          onTap: _isGoogleLoading ? null : _signInWithGoogle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:
                  isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.25),
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isGoogleLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: subtitleColor,
                        ),
                      )
                    : Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                      ),
                const SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: Divider(color: subtitleColor?.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Or',
                  style: TextStyle(color: subtitleColor, fontSize: 13)),
            ),
            Expanded(
                child: Divider(color: subtitleColor?.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 24),
        // Email field
        TextField(
          controller: _emailController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: subtitleColor),
            prefixIcon: Icon(Icons.email_outlined, color: _primaryOrange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: _primaryOrange.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryOrange, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        // Password field
        TextField(
          controller: _passwordController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: subtitleColor),
            prefixIcon: Icon(Icons.lock_outlined, color: _primaryOrange),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: _primaryOrange.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryOrange, width: 2),
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: subtitleColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 24),
        // Primary action button with gradient
        GestureDetector(
          onTap: _isLoading ? null : _submit,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryOrange, Color(0xFFFFBB6E)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isLogin ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() => _isLogin = !_isLogin);
          },
          child: Text(
            _isLogin
                ? "Don't have an account? Sign Up"
                : 'Already have an account? Sign In',
            style: TextStyle(color: _primaryOrange),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Divider(color: subtitleColor?.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Or',
                  style: TextStyle(color: subtitleColor, fontSize: 13)),
            ),
            Expanded(
                child: Divider(color: subtitleColor?.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 20),
        // Continue as Guest button
        GestureDetector(
          onTap: _isLoading ? null : _continueAsGuest,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _secondaryTeal.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, color: _secondaryTeal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _secondaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Try the app without creating an account.\nSome features will be limited.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: subtitleColor?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

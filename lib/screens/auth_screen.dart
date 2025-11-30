import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'profile_setup_screen.dart';
import 'question_flow_screen.dart';

import 'data_restoration_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showOtpInput = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _checkAndCompleteProfile() async {
    print('🔐 _checkAndCompleteProfile: Starting profile check');

    final supabase = SupabaseService();
    final user = supabase.currentUser;

    // Safety check: Ensure email is verified for email providers
    if (user != null &&
        user.appMetadata['provider'] == 'email' &&
        user.emailConfirmedAt == null) {
      print('⚠️ Email not verified. Redirecting to OTP input.');
      setState(() {
        _showOtpInput = true;
        _isLoading = false;
      });
      return;
    }

    var profile = await supabase.getUserProfile();

    print('🔐 Current user ID: ${supabase.currentUser?.id}');
    print('🔐 Current user email: ${supabase.currentUser?.email}');

    if (mounted && (profile == null || profile['age'] == null)) {
      // No profile or age missing, navigate to setup
      print(
          '⚠️ Profile missing or incomplete, navigating to ProfileSetupScreen');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
        ),
      );

      // Refresh profile after setup
      profile = await supabase.getUserProfile();
      print('🔐 Profile after setup: $profile');
    }

    if (mounted && profile != null) {
      final name = profile['username'] ?? 'User';
      final age = profile['age'] ?? 18;

      print('🔐 Profile complete: name=$name, age=$age');
      print('🔍 Checking for existing data...');

      // Check for existing data (habits, etc.)
      final hasData = await supabase.hasExistingData();

      print('🔍 hasExistingData result: $hasData');

      if (mounted) {
        if (hasData) {
          // Restore data flow
          print('✅ Existing data found - navigating to DataRestorationScreen');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => DataRestorationScreen(userName: name),
            ),
            (route) => false,
          );
        } else {
          // New user flow
          print('🆕 No existing data - navigating to QuestionFlowScreen');
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
        _showError('Google Sign-In failed: ${e.toString()}');
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
            print('🔐 Password verified. Starting Step 2: OTP Verification');

            // 3. Send OTP
            await supabase.signInWithOtp(email);

            setState(() {
              _showOtpInput = true;
              _isLoading = false;
            });

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

            print('🔐 Signup Debug:');
            print(
                '   - Session: ${response.session != null ? "Active" : "Null"}');
            print('   - Provider: ${user?.appMetadata['provider']}');
            print('   - Email Confirmed At: ${user?.emailConfirmedAt}');
            print('   - Is Confirmed: $isConfirmed');

            if (response.session != null && (!isEmail || isConfirmed)) {
              print(
                  '✅ Auto-login allowed (Email is confirmed or not email provider)');
              await _checkAndCompleteProfile();
            } else {
              print('🛑 Verification required. Showing OTP screen.');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_showOtpInput
            ? 'Verify Email'
            : (_isLogin ? 'Sign In' : 'Sign Up')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _showOtpInput ? _buildOtpForm(theme) : _buildAuthForm(theme),
      ),
    );
  }

  Widget _buildOtpForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a verification code to ${_emailController.text}',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _otpController,
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            prefixIcon: Icon(Icons.lock_clock_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          maxLength: 8,
          onSubmitted: (_) => _verifyOtp(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify & Continue'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _resendCode,
          child: const Text('Resend Code'),
        ),
        TextButton(
          onPressed: () {
            setState(() => _showOtpInput = false);
          },
          child: const Text('Back to Sign Up'),
        ),
      ],
    );
  }

  Widget _buildAuthForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Icon(
          Icons.cloud_outlined,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome Back!' : 'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to backup and sync your habits'
              : 'Create an account to backup your data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
          icon: _isGoogleLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                ),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isLogin ? 'Sign In' : 'Sign Up'),
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
          ),
        ),
      ],
    );
  }
}

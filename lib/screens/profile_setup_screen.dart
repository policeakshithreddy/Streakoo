import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _ageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ageStr = _ageController.text.trim();

    if (ageStr.isEmpty) {
      _showError('Please enter your age');
      return;
    }

    final age = int.tryParse(ageStr);
    if (age == null || age < 1 || age > 120) {
      _showError('Please enter a valid age');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = SupabaseService();
      final user = supabase.currentUser;
      final username = user?.userMetadata?['full_name'] ??
          user?.email?.split('@')[0] ??
          'User';

      await supabase.updateUserProfile(username: username, age: age);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
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
    final supabase = SupabaseService();
    final user = supabase.currentUser;
    final userName = user?.userMetadata?['full_name'] ??
        user?.email?.split('@')[0] ??
        'User';

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete Your Profile'),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icon
              Icon(
                Icons.person_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Welcome, $userName!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Just one more thing...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Age field
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.cake),
                  border: OutlineInputBorder(),
                  helperText: 'This helps us personalize your experience',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                autofocus: true,
              ),
              const SizedBox(height: 32),

              // Submit button
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
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

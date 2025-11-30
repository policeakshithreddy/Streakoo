import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/health_service.dart';
import 'health_intake_screen.dart';

/// Onboarding screen for connecting health data
class HealthOnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool canSkip;

  const HealthOnboardingScreen({
    super.key,
    this.onComplete,
    this.canSkip = true,
  });

  @override
  State<HealthOnboardingScreen> createState() => _HealthOnboardingScreenState();
}

class _HealthOnboardingScreenState extends State<HealthOnboardingScreen> {
  int _currentPage = 0;
  bool _isConnecting = false;
  String? _errorMessage;

  final PageController _pageController = PageController();

  final List<_OnboardingPage> _pages = [
    const _OnboardingPage(
      emoji: '📊',
      title: 'Track Your Health Automatically',
      description:
          'Connect Google Fit or Samsung Health to automatically track your health habits - no manual input needed!',
      benefits: [
        '📍 Auto-track steps, sleep, and workouts',
        '⚡ Save time - habits complete automatically',
        '🎯 More accurate data from your phone',
        '🔒 Your data stays secure on your device',
      ],
    ),
    const _OnboardingPage(
      emoji: '🎯',
      title: 'Smart Habit Completion',
      description:
          'Create health goals like "Walk 10,000 steps" and watch them auto-complete when you hit your target!',
      benefits: [
        '✨ Set daily step goals',
        '😴 Track sleep hours',
        '🏃 Monitor distance and workouts',
        '❤️ Check heart rate data',
      ],
    ),
    const _OnboardingPage(
      emoji: '🏆',
      title: 'Celebrate Your Wins',
      description:
          'When you hit your health goals, Streakoo celebrates with you - automatically!',
      benefits: [
        '🎉 Instant celebrations when goals met',
        '🔥 Build unstoppable streaks',
        '📈 Track progress over time',
        '💪 Stay motivated with AI coaching',
      ],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _connectHealth();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _connectHealth() async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      // Check for Health Connect on Android
      final status = await HealthService.instance.getHealthConnectSdkStatus();
      if (status == HealthConnectSdkStatus.sdkUnavailable ||
          status ==
              HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
        setState(() {
          _isConnecting = false;
          _errorMessage =
              'Health Connect is required. Redirecting to Play Store...';
        });

        // Use the specific link provided by the user
        final url = Uri.parse(
            'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata&pcampaignid=web_share');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to the SDK's default install method if link fails
          await HealthService.instance.installHealthConnect();
        }
        return;
      }

      final success = await HealthService.instance.requestPermissions();

      setState(() {
        _isConnecting = false;
        if (!success) {
          _errorMessage =
              'Could not get permission. Please enable health data access in your device settings.';
        }
      });

      if (success) {
        // Show success page
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // Navigate to Intake Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HealthIntakeScreen(
                onComplete: () {
                  widget.onComplete?.call();
                  // Navigator.of(context).pop(true); // Already handled by pushReplacement/pop in Intake
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Connection failed: ${e.toString()}';
      });
    }
  }

  void _skip() {
    widget.onComplete?.call();
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (widget.canSkip && _currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skip,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ).animate().scale(duration: 200.ms),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(100, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Back'),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isConnecting ? null : _nextPage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: const Color(0xFF58CC02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentPage == _pages.length - 1
                                  ? 'Connect Health Data'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Emoji icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

          const SizedBox(height: 32),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),

          // Benefits
          ...page.benefits.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (600 + entry.key * 100).ms)
                .slideX(begin: -0.2, end: 0);
          }),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String description;
  final List<String> benefits;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.description,
    required this.benefits,
  });
}

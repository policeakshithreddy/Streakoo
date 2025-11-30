import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'nav_wrapper.dart';

class DataRestorationScreen extends StatefulWidget {
  final String userName;

  const DataRestorationScreen({
    super.key,
    required this.userName,
  });

  @override
  State<DataRestorationScreen> createState() => _DataRestorationScreenState();
}

class _DataRestorationScreenState extends State<DataRestorationScreen> {
  @override
  void initState() {
    super.initState();
    _restoreData();
  }

  Future<void> _restoreData() async {
    // Artificial delay for better UX (so the user sees the welcome message)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      await context.read<AppState>().restoreDataFromCloud();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NavWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to restore data: $e')),
        );
        // Navigate to Home anyway
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NavWrapper()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_sync_outlined,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Welcome back, ${widget.userName}!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Restoring your habits and progress...',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

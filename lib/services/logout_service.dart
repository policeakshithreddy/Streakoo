import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'supabase_service.dart';
import '../screens/welcome_screen.dart';

class LogoutService {
  /// Performs the logout flow with backup prompt and data wipe.
  static Future<void> performLogout(BuildContext context) async {
    final supabase = SupabaseService();
    final appState = context.read<AppState>();

    // If not authenticated, we might still want to reset if the user wants to "logout"
    // (e.g. clear local guest data), but the prompt implies cloud backup which needs auth.
    // For now, we assume this is called for authenticated users or we adapt the prompt.
    final isAuthenticated = supabase.isAuthenticated;

    if (!isAuthenticated) {
      // If guest, just ask to reset/clear data?
      // Or maybe the user just wants to exit?
      // Let's assume this is primarily for the "Log Out" button which is usually shown when auth'd.
      // But if shown when not auth'd, we should handle it.
      // For now, let's proceed with the flow but skip backup option if not auth'd.
    }

    // 1. Show Confirmation Dialog
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: Text(isAuthenticated
            ? 'Do you want to backup your data before logging out?\n\nAll local data will be deleted from this device.'
            : 'All local data will be deleted from this device. Are you sure you want to reset and exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          if (isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'no'),
              child: const Text('No, just logout'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'yes'),
            child:
                Text(isAuthenticated ? 'Yes, Backup & Logout' : 'Yes, Reset'),
          ),
        ],
      ),
    );

    if (result == 'cancel' || result == null) return;

    // 2. Handle Backup (if requested and authenticated)
    if (result == 'yes' && isAuthenticated) {
      // Show loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Backing up data...'),
              ],
            ),
            duration: Duration(seconds: 60), // Longer duration for backup
          ),
        );
      }

      try {
        // Add timeout to prevent indefinite hang
        await appState.backupToCloud().timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            throw TimeoutException(
                'Backup took too long. Please check your internet connection.');
          },
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backup successful!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Show error with options
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Backup Failed'),
              content: Text(
                'Failed to backup data: ${e.toString()}\n\nDo you want to logout anyway?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Logout Anyway'),
                ),
              ],
            ),
          );

          if (shouldContinue != true) return; // User cancelled
        }
      }
    }

    // 3. Perform Wipe and Logout
    print('🔄 Starting wipe and logout...');
    try {
      // Small delay to let success message display
      await Future.delayed(const Duration(milliseconds: 500));

      print('🔄 Wiping local data...');
      // Wipe local data
      await appState.resetAll();
      print('✅ Local data wiped');

      print('🔄 Signing out from Supabase...');
      // Sign out from Supabase
      if (isAuthenticated) {
        await supabase.signOut();
        print('✅ Signed out from Supabase');
      }

      // 4. Navigate to Welcome Screen
      print('🔄 Navigating to Welcome Screen...');
      if (context.mounted) {
        // Navigate to Welcome Screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
        print('✅ Navigation complete');
      }
    } catch (e) {
      // Handle errors
      print('❌ Error during logout:$e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }
}

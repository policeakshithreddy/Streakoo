import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/health_service.dart';
import '../services/health_checker_service.dart';
import '../screens/health_onboarding_screen.dart';
import '../state/app_state.dart';

class HealthConnectionCard extends StatefulWidget {
  const HealthConnectionCard({super.key});

  @override
  State<HealthConnectionCard> createState() => _HealthConnectionCardState();
}

class _HealthConnectionCardState extends State<HealthConnectionCard> {
  bool _isConnected = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Check if using mock data
  bool get _isMockData => !Platform.isIOS && !Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);

    final hasAccess = await HealthService.instance.hasHealthDataAccess();

    setState(() {
      _isConnected = hasAccess;
      _isLoading = false;
      if (hasAccess) {
        _lastSyncTime = DateTime.now();
      }
    });
  }

  Future<void> _syncNow() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final appState = context.read<AppState>();
      await HealthCheckerService.instance.checkAndCompleteHabits(appState);

      setState(() {
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Health data synced successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF58CC02),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connect() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthOnboardingScreen(
          onComplete: () {},
          canSkip: true,
        ),
      ),
    );

    if (result == true) {
      _checkConnection();
      if (mounted) {
        final appState = context.read<AppState>();
        HealthCheckerService.instance.startPeriodicCheck(appState);
      }
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Health Data?'),
        content: const Text(
          'Health-tracked habits will no longer auto-complete. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Note: We can't revoke permissions programmatically
      // User needs to do this in system settings
      setState(() {
        _isConnected = false;
        _lastSyncTime = null;
      });

      HealthCheckerService.instance.stopPeriodicCheck();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Health tracking disabled. Go to device settings to revoke permissions.'),
          ),
        );
      }
    }
  }

  String _getTimeSince(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? const Color(0xFF58CC02).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isConnected ? Icons.favorite : Icons.favorite_border,
                    color: _isConnected ? const Color(0xFF58CC02) : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isConnected
                            ? (_isMockData
                                ? 'Mock Data Active (Dev Mode)'
                                : 'Connected to Health App')
                            : 'Not connected',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isConnected
                              ? const Color(0xFF58CC02)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? (_isMockData
                            ? Colors.orange.withOpacity(0.1)
                            : const Color(0xFF58CC02).withOpacity(0.1))
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isConnected
                              ? (_isMockData
                                  ? Colors.orange
                                  : const Color(0xFF58CC02))
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected
                            ? (_isMockData ? 'Mock Mode' : 'Active')
                            : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isConnected
                              ? (_isMockData
                                  ? Colors.orange
                                  : const Color(0xFF58CC02))
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isConnected) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Last sync info
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _lastSyncTime != null
                        ? 'Last synced ${_getTimeSince(_lastSyncTime!)}'
                        : 'Never synced',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isSyncing ? null : _syncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF58CC02),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Auto-sync enabled',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Health-tracked habits will automatically complete when you reach your goals. Data syncs every 15 minutes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Disconnect button
              OutlinedButton(
                onPressed: _disconnect,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Disconnect'),
              ),
            ] else ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Benefits
              _buildBenefit(
                  Icons.auto_awesome, 'Auto-track steps, sleep, workouts'),
              const SizedBox(height: 12),
              _buildBenefit(
                  Icons.check_circle, 'Habits complete automatically'),
              const SizedBox(height: 12),
              _buildBenefit(Icons.trending_up, 'More accurate health data'),

              const SizedBox(height: 20),

              // Connect button
              FilledButton(
                onPressed: _connect,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF58CC02),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Connect Health Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF58CC02),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

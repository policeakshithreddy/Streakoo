import 'package:flutter/material.dart';
import '../services/health_service.dart';

class HealthConnectionDialog extends StatelessWidget {
  final VoidCallback? onConnected;

  const HealthConnectionDialog({
    super.key,
    this.onConnected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.health_and_safety,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('Connect Health Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To track your health habits, we need access to your health data.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          const _FeatureItem(
            icon: Icons.directions_walk,
            title: 'Steps',
            description: 'Daily step count',
          ),
          const _FeatureItem(
            icon: Icons.bedtime,
            title: 'Sleep',
            description: 'Sleep duration',
          ),
          const _FeatureItem(
            icon: Icons.route,
            title: 'Distance',
            description: 'Distance traveled',
          ),
          const _FeatureItem(
            icon: Icons.favorite,
            title: 'Active Energy',
            description: 'Calories burned',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your health data stays private and is only used to track your habits.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not Now'),
        ),
        FilledButton(
          onPressed: () async {
            final healthService = HealthService.instance;
            final granted = await healthService.requestPermissions();

            if (!context.mounted) return;

            if (granted) {
              Navigator.of(context).pop();
              onConnected?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Health data connected successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Health permission denied'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Connect'),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/gradients.dart';

/// Premium subscription screen
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Go Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(DesignTokens.space6),
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: DesignTokens.borderRadiusLG,
              ),
              child: Column(
                children: [
                  const Text(
                    '👑',
                    style: TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  const Text(
                    'Unlock Premium',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Get unlimited access to all features',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: DesignTokens.space6),

            // Features list
            _FeatureRow(icon: '✨', text: 'Unlimited habits', isDark: isDark),
            _FeatureRow(icon: '🎨', text: 'Premium themes', isDark: isDark),
            _FeatureRow(icon: '📊', text: 'Advanced analytics', isDark: isDark),
            _FeatureRow(
                icon: '🌬️', text: 'Priority Wind coaching', isDark: isDark),
            _FeatureRow(
                icon: '📤', text: 'Export reports (PDF/CSV)', isDark: isDark),
            _FeatureRow(
                icon: '🛡️', text: 'Extra streak freezes', isDark: isDark),
            _FeatureRow(icon: '🚫', text: 'Ad-free experience', isDark: isDark),
            _FeatureRow(
                icon: '☁️', text: 'Cloud backup & sync', isDark: isDark),

            const SizedBox(height: DesignTokens.space8),

            // Pricing cards
            _PricingCard(
              title: 'Monthly',
              price: '\$4.99',
              period: '/month',
              isPopular: false,
              onTap: () => _subscribe(context, 'monthly'),
              isDark: isDark,
            ),

            const SizedBox(height: DesignTokens.space3),

            _PricingCard(
              title: 'Yearly',
              price: '\$39.99',
              period: '/year',
              badge: 'Save 33%',
              isPopular: true,
              onTap: () => _subscribe(context, 'yearly'),
              isDark: isDark,
            ),

            const SizedBox(height: DesignTokens.space6),

            // Footer
            Text(
              '• 7-day free trial\n• Cancel anytime\n• Secure payment',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black45,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _subscribe(BuildContext context, String plan) {
    // TODO: Implement subscription logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subscribe to $plan (Coming soon!)')),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String text;
  final bool isDark;

  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA94A).withValues(alpha: 0.15),
              borderRadius: DesignTokens.borderRadiusMD,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: DesignTokens.space3),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool isPopular;
  final VoidCallback onTap;
  final bool isDark;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
    required this.isPopular,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          gradient: isPopular ? AppGradients.primary.withOpacity(0.15) : null,
          color: !isPopular
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : null,
          borderRadius: DesignTokens.borderRadiusLG,
          border: Border.all(
            color: isPopular
                ? const Color(0xFFFFA94A)
                : (isDark ? Colors.white24 : Colors.black12),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27AE60),
                            borderRadius: DesignTokens.borderRadiusSM,
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.white54 : Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

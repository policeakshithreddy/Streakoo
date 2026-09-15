import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../state/app_state.dart';
import '../services/supabase_service.dart';
import 'data_restoration_screen.dart'; // Redirect here after sync

class SyncConflictScreen extends StatefulWidget {
  final List<Habit> localHabits;
  final List<Habit> cloudHabits;
  final String userName;

  const SyncConflictScreen({
    super.key,
    required this.localHabits,
    required this.cloudHabits,
    required this.userName,
  });

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  // Track selected habits by ID (or temporary ID)
  // We'll use a set of "indices" or unique identifiers.
  // Since local and cloud might conflict on IDs if UUIDs were reused (unlikely but possible),
  // or keys might be same.
  // Actually, habits have unique IDs.

  // We will display a combined list.
  late List<_HabitConflictItem> _allItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeItems();
  }

  void _initializeItems() {
    _allItems = [];

    // Add all local habits
    for (var h in widget.localHabits) {
      _allItems.add(_HabitConflictItem(habit: h, source: _HabitSource.local));
    }

    // Add all cloud habits
    // Intelligent matching: if names match exactly, maybe group them?
    // For now, per user request "Select from backup or guest", listing all is safer for "Selective Edit".
    // We can auto-select unique ones.
    for (var h in widget.cloudHabits) {
      // Check if duplicate exists in local
      // Unused logic for now, keeping comments to clarify intent
      // final bool isDuplicateName = widget.localHabits
      //    .any((local) => local.name.toLowerCase() == h.name.toLowerCase());

      _allItems.add(_HabitConflictItem(
        habit: h,
        source: _HabitSource.cloud,
        // If exact name dupe, maybe default unchecked? Or checked?
        // Let's default EVERYTHING to checked for "Merge" behavior, user can untick.
        isSelected: true,
      ));
    }
  }

  Future<void> _processSync() async {
    setState(() => _isLoading = true);

    try {
      final selectedHabits = _allItems
          .where((item) => item.isSelected)
          .map((item) => item.habit)
          .toList();

      debugPrint('🔄 Syncing ${selectedHabits.length} selected habits...');

      // 1. Update Local AppState with the FINAL list
      // We need a method in AppState to "Replace All Habits"
      final appState = context.read<AppState>();
      await appState.overwriteHabits(selectedHabits);

      // 2. Sync to Cloud
      // This ensures the cloud matches exactly what the user selected
      final supabase = SupabaseService();

      // First, we might need to delete habits that were NOT selected if they were in the cloud?
      // Or just upsert everything.
      // SyncService.syncHabitsToCloud typically upserts.
      // If we want to "mirror", we should ideally delete the ones not in list.
      // But for safety, let's just Upsert the new set first.
      await supabase.syncHabitsToCloud(selectedHabits);

      // 3. Navigate to Home (via DataRestoration for smooth transition)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => DataRestorationScreen(userName: widget.userName),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Sync failed: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFFFFA94A);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sync Conflict ☁️'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Text(
                  'Existing Data Found',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have habits on this device (Guest) and in your Backup. Which ones do you want to keep?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // Quick Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                        context,
                        'Select All',
                        Icons.done_all,
                        () => setState(() {
                              for (var item in _allItems) {
                                item.isSelected = true;
                              }
                            })),
                    _buildQuickAction(
                        context,
                        'Select None',
                        Icons.remove_circle_outline,
                        () => setState(() {
                              for (var item in _allItems) {
                                item.isSelected = false;
                              }
                            })),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _allItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _allItems[index];
                return _buildHabitItem(item, isDark);
              },
            ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  // Restore Backup Only (Uncheck all local, check all cloud)
                                  for (var item in _allItems) {
                                    item.isSelected =
                                        item.source == _HabitSource.cloud;
                                  }
                                  _processSync();
                                }),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.5)),
                        ),
                        child: const Text('Restore Backup'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  // Merge All (Check everything)
                                  for (var item in _allItems) {
                                    item.isSelected = true;
                                  }
                                  _processSync();
                                }),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Merge All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isLoading &&
                    _allItems.any((i) => i.isSelected) &&
                    !_allItems.every((i) => i.isSelected))
                  TextButton(
                    onPressed: _processSync,
                    child: Text(
                      'Keep Selected (${_allItems.where((i) => i.isSelected).length})',
                      style: const TextStyle(
                        color: Color(0xFFFFA94A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ).animate().fadeIn(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18, color: isDark ? Colors.grey[400] : Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitItem(_HabitConflictItem item, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => item.isSelected = !item.isSelected),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isSelected
              ? const Color(0xFFFFA94A).withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                item.isSelected ? const Color(0xFFFFA94A) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.source == _HabitSource.local
                    ? const Color(0xFF1FD1A5).withValues(alpha: 0.2)
                    : const Color(0xFF2196F3).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.source == _HabitSource.local ? '📱 Phone' : '☁️ Backup',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: item.source == _HabitSource.local
                      ? const Color(0xFF1FD1A5)
                      : const Color(0xFF2196F3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.habit.customColor != null
                    ? Color(int.parse(
                        item.habit.customColor!.replaceAll('#', '0xFF')))
                    : (isDark ? Colors.grey[800] : Colors.white),
                shape: BoxShape.circle,
              ),
              child:
                  Text(item.habit.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.habit.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (item.habit.streak > 0)
                    Text(
                      '🔥 ${item.habit.streak} day streak',
                      style: TextStyle(fontSize: 12, color: Colors.orange[400]),
                    ),
                ],
              ),
            ),
            Checkbox(
              value: item.isSelected,
              activeColor: const Color(0xFFFFA94A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              onChanged: (v) => setState(() => item.isSelected = v == true),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HabitSource { local, cloud }

class _HabitConflictItem {
  final Habit habit;
  final _HabitSource source;
  bool isSelected;

  _HabitConflictItem({
    required this.habit,
    required this.source,
    this.isSelected = true,
  });
}

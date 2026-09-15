import 'dart:math';

/// Status of partner connection
enum PartnerStatus {
  pending, // Invitation sent, waiting for acceptance
  active, // Connected and active
  blocked, // Blocked by user
}

/// Maximum nudges per partner per day
const int maxDailyNudges = 3;

/// An accountability partner connection
class AccountabilityPartner {
  final String id;
  final String partnerUserId;
  final String partnerName;
  final String? partnerAvatar;
  final PartnerStatus status;
  final DateTime connectedAt;
  final int partnerCurrentStreak; // Total streak across their habits
  final bool hasMissedToday;
  final DateTime? lastNudgeSent;
  final DateTime? lastNudgeReceived;
  final int nudgesTodayCount; // Track daily nudges sent to this partner
  final DateTime? nudgeCountResetDate; // Date when count was last reset

  AccountabilityPartner({
    required this.id,
    required this.partnerUserId,
    required this.partnerName,
    this.partnerAvatar,
    required this.status,
    required this.connectedAt,
    this.partnerCurrentStreak = 0,
    this.hasMissedToday = false,
    this.lastNudgeSent,
    this.lastNudgeReceived,
    this.nudgesTodayCount = 0,
    this.nudgeCountResetDate,
  });

  /// Get actual nudges sent today (resets daily)
  int get nudgesSentToday {
    if (nudgeCountResetDate == null) return 0;
    final now = DateTime.now();
    final isSameDay = nudgeCountResetDate!.year == now.year &&
        nudgeCountResetDate!.month == now.month &&
        nudgeCountResetDate!.day == now.day;
    return isSameDay ? nudgesTodayCount : 0;
  }

  /// Remaining nudges today
  int get remainingNudgesToday => maxDailyNudges - nudgesSentToday;

  /// Can send nudge (max 3 per day)
  bool get canSendNudge => remainingNudgesToday > 0;

  /// Time until can nudge again
  Duration? get nudgeCooldownRemaining {
    if (lastNudgeSent == null) return null;
    final cooldownEnd = lastNudgeSent!.add(const Duration(hours: 4));
    final remaining = cooldownEnd.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  AccountabilityPartner copyWith({
    String? id,
    String? partnerUserId,
    String? partnerName,
    String? partnerAvatar,
    PartnerStatus? status,
    DateTime? connectedAt,
    int? partnerCurrentStreak,
    bool? hasMissedToday,
    DateTime? lastNudgeSent,
    DateTime? lastNudgeReceived,
    int? nudgesTodayCount,
    DateTime? nudgeCountResetDate,
  }) {
    return AccountabilityPartner(
      id: id ?? this.id,
      partnerUserId: partnerUserId ?? this.partnerUserId,
      partnerName: partnerName ?? this.partnerName,
      partnerAvatar: partnerAvatar ?? this.partnerAvatar,
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      partnerCurrentStreak: partnerCurrentStreak ?? this.partnerCurrentStreak,
      hasMissedToday: hasMissedToday ?? this.hasMissedToday,
      lastNudgeSent: lastNudgeSent ?? this.lastNudgeSent,
      lastNudgeReceived: lastNudgeReceived ?? this.lastNudgeReceived,
      nudgesTodayCount: nudgesTodayCount ?? this.nudgesTodayCount,
      nudgeCountResetDate: nudgeCountResetDate ?? this.nudgeCountResetDate,
    );
  }

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) {
    return AccountabilityPartner(
      id: json['id'] as String,
      partnerUserId: json['partner_user_id'] as String,
      partnerName: json['partner_name'] as String? ?? 'Partner',
      partnerAvatar: json['partner_avatar'] as String?,
      status: PartnerStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PartnerStatus.pending,
      ),
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'] as String)
          : DateTime.now(),
      partnerCurrentStreak: json['partner_current_streak'] as int? ?? 0,
      hasMissedToday: json['has_missed_today'] as bool? ?? false,
      lastNudgeSent: json['last_nudge_sent'] != null
          ? DateTime.parse(json['last_nudge_sent'] as String)
          : null,
      lastNudgeReceived: json['last_nudge_received'] != null
          ? DateTime.parse(json['last_nudge_received'] as String)
          : null,
      nudgesTodayCount: json['nudges_today_count'] as int? ?? 0,
      nudgeCountResetDate: json['nudge_count_reset_date'] != null
          ? DateTime.parse(json['nudge_count_reset_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_user_id': partnerUserId,
      'partner_name': partnerName,
      'partner_avatar': partnerAvatar,
      'status': status.name,
      'connected_at': connectedAt.toIso8601String(),
      'partner_current_streak': partnerCurrentStreak,
      'has_missed_today': hasMissedToday,
      'last_nudge_sent': lastNudgeSent?.toIso8601String(),
      'last_nudge_received': lastNudgeReceived?.toIso8601String(),
      'nudges_today_count': nudgesTodayCount,
      'nudge_count_reset_date': nudgeCountResetDate?.toIso8601String(),
    };
  }
}

/// A nudge message between partners
class PartnerNudge {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String message;
  final String? habitName;
  final DateTime sentAt;
  final bool isRead;

  PartnerNudge({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    this.habitName,
    required this.sentAt,
    this.isRead = false,
  });

  factory PartnerNudge.fromJson(Map<String, dynamic> json) {
    return PartnerNudge(
      id: json['id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      message: json['message'] as String,
      habitName: json['habit_name'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'message': message,
      'habit_name': habitName,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

/// Partner invitation code
class PartnerInviteCode {
  final String code;
  final String creatorUserId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  PartnerInviteCode({
    required this.code,
    required this.creatorUserId,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  /// Generate a random 6-character code
  static String generateCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoiding confusing chars
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  factory PartnerInviteCode.create(String userId) {
    return PartnerInviteCode(
      code: generateCode(),
      creatorUserId: userId,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  factory PartnerInviteCode.fromJson(Map<String, dynamic> json) {
    return PartnerInviteCode(
      code: json['code'] as String,
      creatorUserId: json['creator_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'creator_user_id': creatorUserId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
    };
  }
}

/// Pre-defined nudge messages
class NudgeMessages {
  static const List<String> encouraging = [
    "You've got this! 💪",
    "Don't break your streak! 🔥",
    "I believe in you! ⭐",
    "Just 5 minutes - you can do it!",
    "Your future self will thank you! 🙌",
    "Small steps, big results! 🚀",
    "We're in this together! 🤝",
  ];

  static const List<String> gentle = [
    "Hey, checking in on you! 👋",
    "How's your day going?",
    "Remember your goals! 🎯",
    "Taking a break? That's okay! 💚",
    "Ready when you are! ⏰",
  ];

  static const List<String> competitive = [
    "I'm ahead today! Catch up! 🏃",
    "Challenge accepted? 🏆",
    "Race you to complete it! 🏁",
    "Don't let me win this easily! 😜",
  ];

  static String getRandomEncouraging() {
    return encouraging[Random().nextInt(encouraging.length)];
  }

  static String getRandomGentle() {
    return gentle[Random().nextInt(gentle.length)];
  }
}

/// Privacy settings for accountability sharing
class AccountabilityPrivacySettings {
  final bool shareStreak;
  final bool shareHealthScore;
  final bool shareAchievements;
  final bool shareHabitDetails;

  AccountabilityPrivacySettings({
    this.shareStreak = true,
    this.shareHealthScore = true,
    this.shareAchievements = true,
    this.shareHabitDetails = true,
  });

  factory AccountabilityPrivacySettings.fromJson(Map<String, dynamic> json) {
    return AccountabilityPrivacySettings(
      shareStreak: json['share_streak'] as bool? ?? true,
      shareHealthScore: json['share_health_score'] as bool? ?? true,
      shareAchievements: json['share_achievements'] as bool? ?? true,
      shareHabitDetails: json['share_habit_details'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'share_streak': shareStreak,
      'share_health_score': shareHealthScore,
      'share_achievements': shareAchievements,
      'share_habit_details': shareHabitDetails,
    };
  }

  AccountabilityPrivacySettings copyWith({
    bool? shareStreak,
    bool? shareHealthScore,
    bool? shareAchievements,
    bool? shareHabitDetails,
  }) {
    return AccountabilityPrivacySettings(
      shareStreak: shareStreak ?? this.shareStreak,
      shareHealthScore: shareHealthScore ?? this.shareHealthScore,
      shareAchievements: shareAchievements ?? this.shareAchievements,
      shareHabitDetails: shareHabitDetails ?? this.shareHabitDetails,
    );
  }
}

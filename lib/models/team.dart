/// Team models for Streakoo Teams feature
library;

/// Team status enum
enum TeamStatus { pending, active, archived }

/// Team member role
enum TeamRole { creator, member }

/// Team habit status
enum TeamHabitStatus { proposed, active, completed, archived }

/// Main Team model
class Team {
  final String id;
  final String name;
  final String creatorId;
  final int maxMembers;
  final TeamStatus status;
  final int teamStreak;
  final String teamEmoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// List of team members (loaded separately)
  final List<TeamMember> members;

  /// List of team habits (loaded separately)
  final List<TeamHabit> habits;

  Team({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.maxMembers,
    this.status = TeamStatus.pending,
    this.teamStreak = 0,
    this.teamEmoji = '🔥',
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.habits = const [],
  });

  /// Whether the current user is the creator
  bool isCreator(String currentUserId) => creatorId == currentUserId;

  /// Whether the team is full
  bool get isFull => members.length >= maxMembers;

  /// Whether the team is active
  bool get isActive => status == TeamStatus.active;

  /// Member count display
  String get memberCountDisplay => '${members.length}/$maxMembers';

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      creatorId: json['creator_id'] as String,
      maxMembers: json['max_members'] as int,
      status: _parseStatus(json['status'] as String?),
      teamStreak: json['team_streak'] as int? ?? 0,
      teamEmoji: json['team_emoji'] as String? ?? '🔥',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      habits: (json['habits'] as List<dynamic>?)
              ?.map((h) => TeamHabit.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'creator_id': creatorId,
        'max_members': maxMembers,
        'status': status.name,
        'team_streak': teamStreak,
        'team_emoji': teamEmoji,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Team copyWith({
    String? name,
    TeamStatus? status,
    int? teamStreak,
    String? teamEmoji,
    List<TeamMember>? members,
    List<TeamHabit>? habits,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      creatorId: creatorId,
      maxMembers: maxMembers,
      status: status ?? this.status,
      teamStreak: teamStreak ?? this.teamStreak,
      teamEmoji: teamEmoji ?? this.teamEmoji,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      members: members ?? this.members,
      habits: habits ?? this.habits,
    );
  }

  static TeamStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return TeamStatus.active;
      case 'archived':
        return TeamStatus.archived;
      default:
        return TeamStatus.pending;
    }
  }
}

/// Team member model
class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final TeamRole role;
  final String? displayName;
  final String? profilePictureUrl;
  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    this.role = TeamRole.member,
    this.displayName,
    this.profilePictureUrl,
    required this.joinedAt,
  });

  bool get isCreator => role == TeamRole.creator;

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] == 'creator' ? TeamRole.creator : TeamRole.member,
      displayName: json['display_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'role': role.name,
        'display_name': displayName,
        'profile_picture_url': profilePictureUrl,
        'joined_at': joinedAt.toIso8601String(),
      };
}

/// Team invite code model
class TeamInviteCode {
  final String code;
  final String teamId;
  final String createdBy;
  final DateTime expiresAt;
  final int maxUses;
  final int useCount;
  final DateTime createdAt;

  TeamInviteCode({
    required this.code,
    required this.teamId,
    required this.createdBy,
    required this.expiresAt,
    required this.maxUses,
    this.useCount = 0,
    required this.createdAt,
  });

  /// Whether the code is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt) && useCount < maxUses;

  /// Remaining uses
  int get remainingUses => maxUses - useCount;

  /// Time until expiry
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  factory TeamInviteCode.fromJson(Map<String, dynamic> json) {
    return TeamInviteCode(
      code: json['code'] as String,
      teamId: json['team_id'] as String,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      maxUses: json['max_uses'] as int,
      useCount: json['use_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'team_id': teamId,
        'created_by': createdBy,
        'expires_at': expiresAt.toIso8601String(),
        'max_uses': maxUses,
        'use_count': useCount,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Team habit model
class TeamHabit {
  final String id;
  final String teamId;
  final String name;
  final String emoji;
  final String? description;
  final String? createdBy;
  final TeamHabitStatus status;
  final int targetDays;
  final DateTime createdAt;

  /// Progress for each team member (loaded separately)
  final Map<String, List<DateTime>> memberProgress;

  TeamHabit({
    required this.id,
    required this.teamId,
    required this.name,
    this.emoji = '✅',
    this.description,
    this.createdBy,
    this.status = TeamHabitStatus.active,
    this.targetDays = 7,
    required this.createdAt,
    this.memberProgress = const {},
  });

  bool get isActive => status == TeamHabitStatus.active;

  factory TeamHabit.fromJson(Map<String, dynamic> json) {
    return TeamHabit(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '✅',
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      status: _parseHabitStatus(json['status'] as String?),
      targetDays: json['target_days'] as int? ?? 7,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'emoji': emoji,
        'description': description,
        'created_by': createdBy,
        'status': status.name,
        'target_days': targetDays,
        'created_at': createdAt.toIso8601String(),
      };

  TeamHabit copyWith({
    String? name,
    String? emoji,
    String? description,
    TeamHabitStatus? status,
    Map<String, List<DateTime>>? memberProgress,
  }) {
    return TeamHabit(
      id: id,
      teamId: teamId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      description: description ?? this.description,
      createdBy: createdBy,
      status: status ?? this.status,
      targetDays: targetDays,
      createdAt: createdAt,
      memberProgress: memberProgress ?? this.memberProgress,
    );
  }

  static TeamHabitStatus _parseHabitStatus(String? status) {
    switch (status) {
      case 'proposed':
        return TeamHabitStatus.proposed;
      case 'completed':
        return TeamHabitStatus.completed;
      case 'archived':
        return TeamHabitStatus.archived;
      default:
        return TeamHabitStatus.active;
    }
  }
}

/// Team habit progress entry
class TeamHabitProgress {
  final String id;
  final String teamHabitId;
  final String userId;
  final DateTime completedDate;
  final DateTime completedAt;

  TeamHabitProgress({
    required this.id,
    required this.teamHabitId,
    required this.userId,
    required this.completedDate,
    required this.completedAt,
  });

  factory TeamHabitProgress.fromJson(Map<String, dynamic> json) {
    return TeamHabitProgress(
      id: json['id'] as String,
      teamHabitId: json['team_habit_id'] as String,
      userId: json['user_id'] as String,
      completedDate: DateTime.parse(json['completed_date'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_habit_id': teamHabitId,
        'user_id': userId,
        'completed_date': completedDate.toIso8601String().split('T')[0],
        'completed_at': completedAt.toIso8601String(),
      };
}

/// Team reaction model
class TeamReaction {
  final String id;
  final String teamId;
  final String fromUserId;
  final String? toUserId;
  final String emoji;
  final String? message;
  final DateTime createdAt;

  TeamReaction({
    required this.id,
    required this.teamId,
    required this.fromUserId,
    this.toUserId,
    required this.emoji,
    this.message,
    required this.createdAt,
  });

  factory TeamReaction.fromJson(Map<String, dynamic> json) {
    return TeamReaction(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String?,
      emoji: json['emoji'] as String,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'emoji': emoji,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}

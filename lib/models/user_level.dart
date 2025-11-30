class UserLevel {
  int currentXP;
  int level;
  List<String> unlockedAvatars;
  String currentAvatar;

  UserLevel({
    this.currentXP = 0,
    this.level = 1,
    this.unlockedAvatars = const ['assets/avatars/default.png'],
    this.currentAvatar = 'assets/avatars/default.png',
  });

  // XP needed for next level: level * 100
  int get xpToNextLevel => level * 100;

  double get progress => currentXP / xpToNextLevel;
  double get progressToNextLevel => progress;

  String get titleName {
    if (level < 5) return 'Novice';
    if (level < 10) return 'Apprentice';
    if (level < 20) return 'Master';
    if (level < 50) return 'Grandmaster';
    return 'Legend';
  }

  void addXP(int amount) {
    currentXP += amount;
    checkLevelUp();
  }

  bool checkLevelUp() {
    if (currentXP >= xpToNextLevel) {
      currentXP -= xpToNextLevel;
      level++;
      return true; // Leveled up!
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'currentXP': currentXP,
        'level': level,
        'unlockedAvatars': unlockedAvatars,
        'currentAvatar': currentAvatar,
      };

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      currentXP: json['currentXP'] ?? 0,
      level: json['level'] ?? 1,
      unlockedAvatars: List<String>.from(
          json['unlockedAvatars'] ?? ['assets/avatars/default.png']),
      currentAvatar: json['currentAvatar'] ?? 'assets/avatars/default.png',
    );
  }

  factory UserLevel.fromTotalXP(int totalXP) {
    int level = 1;
    int xp = totalXP;

    // Simple calculation: Level N requires N*100 XP
    while (xp >= level * 100) {
      xp -= level * 100;
      level++;
    }

    return UserLevel(
      currentXP: xp,
      level: level,
      // Default avatars for new user
      unlockedAvatars: ['assets/avatars/default.png'],
      currentAvatar: 'assets/avatars/default.png',
    );
  }
}

class Avatar {
  final String id;
  final String assetPath;
  final String name;
  final int unlockLevel;

  const Avatar({
    required this.id,
    required this.assetPath,
    required this.name,
    required this.unlockLevel,
  });
}

const List<Avatar> availableAvatars = [
  Avatar(
      id: 'default',
      assetPath: 'assets/avatars/default.png',
      name: 'Novice',
      unlockLevel: 1),
  Avatar(
      id: 'level5',
      assetPath: 'assets/avatars/level5.png',
      name: 'Apprentice',
      unlockLevel: 5),
  Avatar(
      id: 'level10',
      assetPath: 'assets/avatars/level10.png',
      name: 'Master',
      unlockLevel: 10),
  Avatar(
      id: 'level20',
      assetPath: 'assets/avatars/level20.png',
      name: 'Grandmaster',
      unlockLevel: 20),
  Avatar(
      id: 'level50',
      assetPath: 'assets/avatars/level50.png',
      name: 'Legend',
      unlockLevel: 50),
];

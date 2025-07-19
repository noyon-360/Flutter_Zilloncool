import 'package:shared_preferences/shared_preferences.dart';

/// Manages level progress and user game state
class LevelProgressController {
  static const String _currentLevelKey = 'current_level';
  static const String _completedLevelsKey = 'completed_levels';
  static const String _unlockedLevelsKey = 'unlocked_levels';
  
  static SharedPreferences? _prefs;
  
  /// Initialize SharedPreferences - call this in main.dart
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Get current active level (the level user is currently playing)
  static int getCurrentLevel() {
    return _prefs?.getInt(_currentLevelKey) ?? 1; // Default to level 1
  }
  
  /// Set current active level
  static Future<void> setCurrentLevel(int level) async {
    await _prefs?.setInt(_currentLevelKey, level);
  }
  
  /// Get list of completed level numbers
  static List<int> getCompletedLevels() {
    final completedString = _prefs?.getString(_completedLevelsKey) ?? '';
    if (completedString.isEmpty) return [];
    return completedString.split(',').map((e) => int.parse(e)).toList();
  }
  
  /// Mark a level as completed and unlock next level
  static Future<void> completeLevel(int level) async {
    final completed = getCompletedLevels();
    if (!completed.contains(level)) {
      completed.add(level);
      await _prefs?.setString(_completedLevelsKey, completed.join(','));
    }
    
    // Unlock next level and set it as current
    final nextLevel = level + 1;
    await unlockLevel(nextLevel);
    await setCurrentLevel(nextLevel);
  }
  
  /// Get list of unlocked level numbers
  static List<int> getUnlockedLevels() {
    final unlockedString = _prefs?.getString(_unlockedLevelsKey) ?? '1'; // Level 1 is always unlocked
    return unlockedString.split(',').map((e) => int.parse(e)).toList();
  }
  
  /// Unlock a specific level
  static Future<void> unlockLevel(int level) async {
    final unlocked = getUnlockedLevels();
    if (!unlocked.contains(level)) {
      unlocked.add(level);
      await _prefs?.setString(_unlockedLevelsKey, unlocked.join(','));
    }
  }
  
  /// Check if a level is completed
  static bool isLevelCompleted(int level) {
    return getCompletedLevels().contains(level);
  }
  
  /// Check if a level is unlocked (available to play)
  static bool isLevelUnlocked(int level) {
    return getUnlockedLevels().contains(level);
  }
  
  /// Get level status for UI styling
  static LevelStatus getLevelStatus(int level) {
    if (isLevelCompleted(level)) {
      return LevelStatus.completed;
    } else if (getCurrentLevel() == level) {
      return LevelStatus.current;
    } else if (isLevelUnlocked(level)) {
      return LevelStatus.unlocked;
    } else {
      return LevelStatus.locked;
    }
  }
  
  /// Reset all progress (for testing or reset functionality)
  static Future<void> resetProgress() async {
    await _prefs?.remove(_currentLevelKey);
    await _prefs?.remove(_completedLevelsKey);
    await _prefs?.remove(_unlockedLevelsKey);
  }
}

/// Enum to represent different level states
enum LevelStatus {
  completed,    // Level is finished
  current,      // Level user is currently on
  unlocked,     // Level is available to play
  locked        // Level is not yet available
}
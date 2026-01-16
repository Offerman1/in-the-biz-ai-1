import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage the app tour (coach marks)
/// Handles tour state, progress tracking, and navigation lock
class TourService extends ChangeNotifier {
  bool _isActive = false;
  int _currentStep = 0;
  String _expectedScreen = 'dashboard';
  String? _expectedSettingsTab;
  bool _isTourButtonHidden = false;
  String?
      _pulsingTarget; // Which button should be pulsing (e.g., 'addShift', 'calendar', etc.)
  bool _isSkippingToScreen =
      false; // Flag to prevent callbacks from interfering during skip

  // Getters
  bool get isActive => _isActive;
  int get currentStep => _currentStep;
  String get expectedScreen => _expectedScreen;
  String? get expectedSettingsTab => _expectedSettingsTab;
  int get totalSteps => 43; // Total tour steps (updated to match roadmap)
  bool get isTourButtonHidden => _isTourButtonHidden;
  String? get pulsingTarget => _pulsingTarget;
  bool get isSkippingToScreen => _isSkippingToScreen;

  /// Check if we're on the job prerequisite step
  bool get isJobPrerequisiteStep => _currentStep == -1;

  /// Set which target should be pulsing
  void setPulsingTarget(String? target) {
    _pulsingTarget = target;
    notifyListeners();
  }

  /// Clear pulsing target
  void clearPulsingTarget() {
    _pulsingTarget = null;
    notifyListeners();
  }

  /// Clear the skipping flag (call after handling skip)
  void clearSkippingFlag() {
    _isSkippingToScreen = false;
  }

  // SharedPreferences keys
  static const String _keyTourComplete = 'tour_complete';
  static const String _keyCurrentStep = 'tour_current_step';
  static const String _keyExpectedScreen = 'tour_expected_screen';
  static const String _keyExpectedSettingsTab = 'tour_expected_settings_tab';
  static const String _keyTourButtonHidden = 'tour_button_hidden';

  /// Start the tour from beginning
  /// If checkJobs is true, starts at step -1 (job prerequisite check)
  Future<void> startTour({bool checkJobs = false}) async {
    _isActive = true;
    _currentStep = checkJobs ? -1 : 0;
    _expectedScreen = 'dashboard';
    _expectedSettingsTab = null;
    await saveTourProgress();
    debugPrint(
        '🎯 TourService: Tour started - step $_currentStep, screen: dashboard');
    notifyListeners();
  }

  /// Resume tour if it was incomplete
  Future<void> resumeTour() async {
    await loadTourProgress();
    if (_currentStep > 0 && _currentStep < totalSteps) {
      _isActive = true;
      notifyListeners();
    }
  }

  /// Move to next step
  void nextStep() {
    _currentStep++;
    _updateExpectedScreen();
    saveTourProgress();
    notifyListeners();
  }

  /// Skip current step
  void skipStep() {
    nextStep();
  }

  /// Skip to a specific screen's tour
  /// This allows users to skip ahead without ending the entire tour
  void skipToScreen(String screenName) {
    _isSkippingToScreen =
        true; // Set flag to prevent onFinish/onSkip interference
    switch (screenName) {
      case 'addShift':
        _currentStep = 10; // First step of Add Shift tour
        _expectedScreen = 'addShift';
        break;
      case 'calendar':
        _currentStep =
            12; // First step of Calendar tour (after simplified Add Shift)
        _expectedScreen = 'calendar';
        break;
      case 'chat':
        _currentStep = 18; // First step of Chat tour
        _expectedScreen = 'chat';
        break;
      case 'stats':
        _currentStep = 24; // First step of Stats tour
        _expectedScreen = 'stats';
        break;
      case 'settings':
        _currentStep = 28; // First step of Settings tour
        _expectedScreen = 'settings';
        break;
      default:
        debugPrint('⚠️ Unknown screen: $screenName');
        _isSkippingToScreen = false;
        return;
    }
    saveTourProgress();
    notifyListeners();
    debugPrint('🎯 Skipped to $screenName tour (step $_currentStep)');
  }

  /// Skip all remaining steps and end tour
  Future<void> skipAll() async {
    _isActive = false;
    _currentStep = totalSteps;
    await _markTourComplete();
    notifyListeners();
  }

  /// Complete the tour
  Future<void> completeTour() async {
    _isActive = false;
    _currentStep = totalSteps;
    await _markTourComplete();
    notifyListeners();
  }

  /// Reset tour to beginning (for "Take a Tour" from Settings)
  Future<void> resetTour() async {
    _currentStep = 0;
    _expectedScreen = 'dashboard';
    _expectedSettingsTab = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTourComplete, false);
    await saveTourProgress();
    _isActive = true;
    notifyListeners();
  }

  /// Check if tour should resume on this screen
  void checkAndResume(String screenName) {
    if (!_isActive) return;

    // Only proceed if we're on the expected screen
    if (screenName == _expectedScreen) {
      notifyListeners();
    }
  }

  /// Check if user can navigate to a specific destination during tour
  bool canNavigateTo(String destination) {
    if (!_isActive) return true; // No tour, allow all navigation

    // Map step numbers to allowed navigation destinations
    if (_currentStep >= 0 && _currentStep <= 5) {
      // Dashboard steps - only allow navigation when tour tells them to
      return destination == 'dashboard' ||
          (_currentStep == 5 && destination == 'calendar');
    } else if (_currentStep >= 6 && _currentStep <= 7) {
      // Calendar steps
      return destination == 'calendar' ||
          (_currentStep == 7 && destination == 'chat');
    } else if (_currentStep >= 8 && _currentStep <= 9) {
      // Chat steps
      return destination == 'chat' ||
          (_currentStep == 9 && destination == 'stats');
    } else if (_currentStep >= 10 && _currentStep <= 11) {
      // Stats steps - allow navigation back or to add shift
      return destination == 'stats' || destination == 'dashboard';
    }

    return false;
  }

  /// Update expected screen based on current step
  void _updateExpectedScreen() {
    if (_currentStep == -1) {
      _expectedScreen =
          'dashboard'; // Job prerequisite check happens on dashboard
    } else if (_currentStep >= 0 && _currentStep <= 9) {
      _expectedScreen = 'dashboard';
    } else if (_currentStep >= 10 && _currentStep <= 11) {
      _expectedScreen = 'addShift';
    } else if (_currentStep >= 12 && _currentStep <= 17) {
      _expectedScreen = 'calendar';
    } else if (_currentStep >= 18 && _currentStep <= 23) {
      _expectedScreen = 'chat';
    } else if (_currentStep >= 24 && _currentStep <= 27) {
      _expectedScreen = 'stats';
    } else if (_currentStep >= 28 && _currentStep <= 32) {
      _expectedScreen = 'settings';
    } else {
      // Tour complete or beyond
      _expectedScreen = 'complete';
    }
  }

  /// Save tour progress to SharedPreferences
  Future<void> saveTourProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCurrentStep, _currentStep);
      await prefs.setString(_keyExpectedScreen, _expectedScreen);
      if (_expectedSettingsTab != null) {
        await prefs.setString(_keyExpectedSettingsTab, _expectedSettingsTab!);
      }
    } catch (e) {
      debugPrint('Error saving tour progress: $e');
    }
  }

  /// Load tour progress from SharedPreferences
  Future<void> loadTourProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isComplete = prefs.getBool(_keyTourComplete) ?? false;

      if (isComplete) {
        _isActive = false;
        _currentStep = totalSteps;
        return;
      }

      _currentStep = prefs.getInt(_keyCurrentStep) ?? 0;
      _expectedScreen = prefs.getString(_keyExpectedScreen) ?? 'dashboard';
      _expectedSettingsTab = prefs.getString(_keyExpectedSettingsTab);

      // If there's saved progress, mark tour as active
      if (_currentStep > 0 && _currentStep < totalSteps) {
        _isActive = true;
      }
    } catch (e) {
      debugPrint('Error loading tour progress: $e');
      _isActive = false;
    }
  }

  /// Mark tour as complete
  Future<void> _markTourComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTourComplete, true);
      await prefs.remove(_keyCurrentStep);
      await prefs.remove(_keyExpectedScreen);
      await prefs.remove(_keyExpectedSettingsTab);
    } catch (e) {
      debugPrint('Error marking tour complete: $e');
    }
  }

  /// Check if tour has been completed before
  Future<bool> isTourComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyTourComplete) ?? false;
    } catch (e) {
      debugPrint('Error checking tour completion: $e');
      return true; // Default to complete to avoid showing tour on error
    }
  }

  /// Hide the floating tour button permanently
  Future<void> hideTourButton() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTourButtonHidden, true);
      _isTourButtonHidden = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error hiding tour button: $e');
    }
  }

  /// Show the floating tour button again (from Settings)
  Future<void> showTourButton() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTourButtonHidden, false);
      _isTourButtonHidden = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error showing tour button: $e');
    }
  }

  /// Load tour button visibility preference
  Future<void> loadTourButtonVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTourButtonHidden = prefs.getBool(_keyTourButtonHidden) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tour button visibility: $e');
    }
  }
}

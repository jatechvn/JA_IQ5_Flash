import 'dart:async';
import 'package:flutter/widgets.dart';

/// Single source of truth for window activity, focus state, and animation policies.
///
/// Ensures continuous animations (MeshOrb, RotatingGlowBorder, MarqueeText)
/// are cleanly coordinated and paused when the window is inactive or hidden,
/// eliminating continuous draw calls and saving GPU/CPU resources.
class AppPowerManager {
  static final AppPowerManager _instance = AppPowerManager._internal();
  static AppPowerManager get instance => _instance;

  AppPowerManager._internal();

  /// Visible for testing constructor to allow clean isolated testing
  @visibleForTesting
  AppPowerManager.create() {
    _initNotifiers();
  }

  bool _isWindowFocused = true;
  bool _isWindowVisible = true;
  bool _isUserIdle = false;

  // Throttling for user interaction recording
  DateTime _lastInteractionRecorded = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _idleTimer;
  Duration _idleTimeout = const Duration(seconds: 12);
  bool _enableIdleSleep = true;

  late final ValueNotifier<bool> backgroundAnimationNotifier =
      ValueNotifier<bool>(true);
  late final ValueNotifier<bool> indicatorsAnimationNotifier =
      ValueNotifier<bool>(true);
  late final ValueNotifier<bool> marqueeAnimationNotifier = ValueNotifier<bool>(
    true,
  );

  void _initNotifiers() {
    // Already initialized inline
  }

  // --- Getters ---
  bool get isWindowFocused => _isWindowFocused;
  bool get isWindowVisible => _isWindowVisible;
  bool get isUserIdle => _isUserIdle;
  bool get enableIdleSleep => _enableIdleSleep;
  Duration get idleTimeout => _idleTimeout;

  /// Background drift animations (MeshOrb): paused when inactive, hidden, or idle >= 12s
  bool get shouldAnimateBackground =>
      _isWindowVisible &&
      _isWindowFocused &&
      (!_enableIdleSleep || !_isUserIdle);

  /// Status indicators (RotatingGlowBorder): paused when inactive or hidden
  bool get shouldAnimateIndicators => _isWindowVisible && _isWindowFocused;

  /// Text marquees (AsymmetricMarqueeText): paused when inactive or hidden
  bool get shouldAnimateMarquee => _isWindowVisible && _isWindowFocused;

  // --- Configuration ---
  void setEnableIdleSleep(bool enable) {
    if (_enableIdleSleep != enable) {
      _enableIdleSleep = enable;
      if (!enable) {
        _idleTimer?.cancel();
        _isUserIdle = false;
      } else if (_isWindowFocused && !_isUserIdle) {
        _rescheduleIdleTimer();
      }
      _updatePolicies();
    }
  }

  void setIdleTimeout(Duration duration) {
    if (_idleTimeout == duration) return;
    _idleTimeout = duration;
    if (_isWindowFocused && !_isUserIdle) {
      _rescheduleIdleTimer();
    }
  }

  // --- State Updates & Handlers ---

  /// Called when the native window receives focus
  void onWindowFocus() {
    _isWindowFocused = true;
    _isWindowVisible = true;
    _isUserIdle = false;
    _rescheduleIdleTimer();
    _updatePolicies();
  }

  /// Called when the native window loses focus (click out, Alt+Tab, etc.)
  void onWindowBlur() {
    _isWindowFocused = false;
    _idleTimer?.cancel();
    _updatePolicies();
  }

  /// Called when the native window is minimized to the taskbar
  void onWindowMinimize() {
    _isWindowVisible = false;
    _isWindowFocused = false;
    _idleTimer?.cancel();
    _updatePolicies();
  }

  /// Called when the native window is restored from minimized state.
  /// Note: Restore makes the window visible, but does NOT automatically imply focus.
  void onWindowRestore() {
    _isWindowVisible = true;
    _updatePolicies();
  }

  /// Called by Flutter AppLifecycleListener
  void onLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isWindowVisible = true;
        _isWindowFocused = true;
        _isUserIdle = false;
        _rescheduleIdleTimer();
        break;
      case AppLifecycleState.inactive:
        _isWindowFocused = false;
        _idleTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isWindowVisible = false;
        _isWindowFocused = false;
        _idleTimer?.cancel();
        break;
    }
    _updatePolicies();
  }

  /// Records user interaction (pointer hover, click, scroll, key press) with throttling
  void recordUserInteraction() {
    final now = DateTime.now();
    // Throttle to at most once every 600ms to avoid rebuilding timers on every pixel move
    if (now.difference(_lastInteractionRecorded).inMilliseconds < 600) {
      return;
    }
    _lastInteractionRecorded = now;

    if (_isUserIdle) {
      _isUserIdle = false;
      _updatePolicies();
    }
    _rescheduleIdleTimer();
  }

  void _rescheduleIdleTimer() {
    _idleTimer?.cancel();
    if (!_enableIdleSleep || !_isWindowFocused || !_isWindowVisible) {
      return;
    }
    _idleTimer = Timer(_idleTimeout, () {
      if (_isWindowFocused && _isWindowVisible && !_isUserIdle) {
        _isUserIdle = true;
        _updatePolicies();
      }
    });
  }

  void _updatePolicies() {
    final bg = shouldAnimateBackground;
    if (backgroundAnimationNotifier.value != bg) {
      backgroundAnimationNotifier.value = bg;
    }

    final ind = shouldAnimateIndicators;
    if (indicatorsAnimationNotifier.value != ind) {
      indicatorsAnimationNotifier.value = ind;
    }

    final marq = shouldAnimateMarquee;
    if (marqueeAnimationNotifier.value != marq) {
      marqueeAnimationNotifier.value = marq;
    }
  }

  /// Visible for testing to reset state between tests
  @visibleForTesting
  void resetForTesting({
    bool isFocused = true,
    bool isVisible = true,
    bool isIdle = false,
  }) {
    _idleTimer?.cancel();
    _isWindowFocused = isFocused;
    _isWindowVisible = isVisible;
    _isUserIdle = isIdle;
    _updatePolicies();
  }

  void dispose() {
    _idleTimer?.cancel();
    backgroundAnimationNotifier.dispose();
    indicatorsAnimationNotifier.dispose();
    marqueeAnimationNotifier.dispose();
  }
}

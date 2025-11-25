import 'dart:async';
import 'package:flutter/material.dart';

class PerformanceUtils {
  static Timer? _debounceTimer;
  
  /// Debounce function to prevent excessive calls
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
  
  /// Throttle function to limit call frequency
  static bool _throttleActive = false;
  
  static void throttle(Duration delay, VoidCallback callback) {
    if (!_throttleActive) {
      _throttleActive = true;
      callback();
      Timer(delay, () {
        _throttleActive = false;
      });
    }
  }
  
  /// Batch operations to reduce UI updates
  static void batchOperation(List<VoidCallback> operations) {
    for (final operation in operations) {
      operation();
    }
  }
}
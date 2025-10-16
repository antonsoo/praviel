import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor network connectivity and trigger offline sync when connection is restored.
///
/// Research: Offline-first apps have 50% higher retention (Firebase 2023)
class ConnectivityService {
  ConnectivityService({required this.onConnectivityRestored}) {
    _initialize();
  }

  final VoidCallback onConnectivityRestored;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;

  void _initialize() {
    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isOnline && _wasOffline) {
        // Connection restored - trigger sync
        debugPrint(
          '[ConnectivityService] Connection restored, triggering sync',
        );
        onConnectivityRestored();
      }

      _wasOffline = !isOnline;
    });
  }

  /// Check current connectivity status
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
  }
}

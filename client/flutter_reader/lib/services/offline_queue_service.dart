import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Offline mutation queue service
///
/// Queues API mutations (POST/PUT/DELETE) when offline and replays them when connectivity is restored.
/// This ensures no user actions are lost due to network issues.
class OfflineQueueService extends ChangeNotifier {
  OfflineQueueService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  static const String _queueKey = 'offline_mutation_queue';

  List<PendingMutation> _queue = [];
  bool _isProcessing = false;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<PendingMutation> get queue => List.unmodifiable(_queue);
  bool get isProcessing => _isProcessing;
  bool get isOnline => _isOnline;
  int get pendingCount => _queue.length;

  /// Initialize the service - load queue and start connectivity monitoring
  Future<void> initialize() async {
    await _loadQueue();
    _startConnectivityMonitoring();

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    // If online, process queue
    if (_isOnline && _queue.isNotEmpty) {
      await processQueue();
    }

    notifyListeners();
  }

  /// Add a mutation to the queue
  Future<void> enqueueMutation({
    required String endpoint,
    required String method, // POST, PUT, DELETE
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    String? description,
  }) async {
    final mutation = PendingMutation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      endpoint: endpoint,
      method: method,
      body: body,
      headers: headers ?? {},
      description: description,
      timestamp: DateTime.now(),
    );

    _queue.add(mutation);
    await _saveQueue();
    notifyListeners();

    debugPrint(
      '[OfflineQueue] Enqueued mutation: ${mutation.description ?? mutation.endpoint} (${_queue.length} pending)',
    );

    // Try to process immediately if online
    if (_isOnline && !_isProcessing) {
      await processQueue();
    }
  }

  /// Process all pending mutations
  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;
    notifyListeners();

    // Purge stale mutations (older than 24 hours) before processing
    final staleMutations = _queue.where((m) => m.isStale).toList();
    if (staleMutations.isNotEmpty) {
      _queue.removeWhere((m) => m.isStale);
      debugPrint(
        '[OfflineQueue] Purged ${staleMutations.length} stale mutations (>24h old)',
      );
    }

    if (_queue.isEmpty) {
      _isProcessing = false;
      notifyListeners();
      return;
    }

    debugPrint(
      '[OfflineQueue] Processing ${_queue.length} pending mutations...',
    );

    final failedMutations = <PendingMutation>[];

    for (final mutation in List.from(_queue)) {
      try {
        // Increment retry count
        mutation.retryCount++;

        // If retried too many times (>10), mark as stale and skip
        if (mutation.retryCount > 10) {
          debugPrint(
            '[OfflineQueue] ✗ Giving up on mutation after 10 retries: ${mutation.description ?? mutation.endpoint}',
          );
          continue;
        }

        await _executeMutation(mutation);
        _queue.remove(mutation);
        debugPrint(
          '[OfflineQueue] ✓ Successfully executed: ${mutation.description ?? mutation.endpoint}',
        );
      } catch (e) {
        debugPrint(
          '[OfflineQueue] ✗ Failed to execute (retry ${mutation.retryCount}): ${mutation.description ?? mutation.endpoint} - $e',
        );
        failedMutations.add(mutation);
      }
    }

    // Keep failed mutations in queue
    _queue = failedMutations;
    await _saveQueue();

    _isProcessing = false;
    notifyListeners();

    if (_queue.isEmpty) {
      debugPrint('[OfflineQueue] All mutations processed successfully');
    } else {
      debugPrint(
        '[OfflineQueue] ${_queue.length} mutations failed, will retry later',
      );
    }
  }

  /// Clear all pending mutations (use with caution!)
  Future<void> clearQueue() async {
    _queue.clear();
    await _saveQueue();
    notifyListeners();
    debugPrint('[OfflineQueue] Queue cleared');
  }

  /// Remove a specific mutation from queue
  Future<void> removeMutation(String mutationId) async {
    _queue.removeWhere((m) => m.id == mutationId);
    await _saveQueue();
    notifyListeners();
  }

  // Private methods

  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result.every((r) => r != ConnectivityResult.none);

      debugPrint(
        '[OfflineQueue] Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}',
      );

      // If just came back online, process queue
      if (wasOffline && _isOnline && _queue.isNotEmpty) {
        debugPrint(
          '[OfflineQueue] Connection restored, processing ${_queue.length} pending mutations',
        );
        unawaited(processQueue());
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);

      if (queueJson != null) {
        final list = jsonDecode(queueJson) as List;
        _queue = list
            .map(
              (json) => PendingMutation.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        debugPrint(
          '[OfflineQueue] Loaded ${_queue.length} pending mutations from storage',
        );
      }
    } catch (e) {
      debugPrint('[OfflineQueue] Error loading queue: $e');
      _queue = [];
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_queue.map((m) => m.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
    } catch (e) {
      debugPrint('[OfflineQueue] Error saving queue: $e');
    }
  }

  Future<void> _executeMutation(PendingMutation mutation) async {
    final client = http.Client();
    try {
      final uri = Uri.parse(mutation.endpoint);
      final headers = {
        'Content-Type': 'application/json',
        ...mutation.headers,
      };

      http.Response response;
      switch (mutation.method.toUpperCase()) {
        case 'POST':
          response = await client
              .post(
                uri,
                headers: headers,
                body: jsonEncode(mutation.body),
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          response = await client
              .put(
                uri,
                headers: headers,
                body: jsonEncode(mutation.body),
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'PATCH':
          response = await client
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(mutation.body),
              )
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          response = await client
              .delete(
                uri,
                headers: headers,
              )
              .timeout(const Duration(seconds: 30));
          break;
        default:
          throw Exception('Unsupported HTTP method: ${mutation.method}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } finally {
      client.close();
    }
  }
}

/// Pending mutation model
class PendingMutation {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final String? description;
  final DateTime timestamp;
  int retryCount;

  PendingMutation({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.body,
    required this.headers,
    this.description,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory PendingMutation.fromJson(Map<String, dynamic> json) {
    return PendingMutation(
      id: json['id'] as String,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      body: Map<String, dynamic>.from(json['body'] as Map),
      headers: Map<String, String>.from(json['headers'] as Map),
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'body': body,
      'headers': headers,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  /// Age of the mutation in hours
  int get ageInHours {
    final now = DateTime.now();
    return now.difference(timestamp).inHours;
  }

  /// Is this mutation stale (older than 24 hours)?
  bool get isStale => ageInHours > 24;
}

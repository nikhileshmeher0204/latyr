import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:uuid/uuid.dart';

class CaptureRepository {
  final AppDatabase db;
  final ApiClient apiClient;
  final SseClient? sseClient;
  final Uuid _uuid = const Uuid();

  CaptureRepository({
    required this.db,
    required this.apiClient,
    this.sseClient,
  }) {
    _initSseListener();
  }

  void _initSseListener() {
    sseClient?.events.listen((event) async {
      if (event.eventType == 'CAPTURE_COMPLETED') {
        final captureId = event.data['capture_id']?.toString();
        if (captureId != null) {
          final existing = await db.getCaptureByServerId(captureId);
          if (existing != null) {
            await db.updateCapture(
              LocalCapturesCompanion(
                id: Value(existing.id),
                serverCaptureId: Value(captureId),
                status: const Value('COMPLETED'),
                intent: Value(event.data['intent']?.toString()),
                category: Value(event.data['category']?.toString()),
                originalCaption: Value(event.data['original_caption']?.toString()),
                audioTranscript: Value(event.data['audio_transcript']?.toString()),
                entitiesJson: Value(event.data['entities'] != null ? jsonEncode(event.data['entities']) : null),
                updatedAt: Value(DateTime.now()),
                syncedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
    });
  }

  Stream<List<LocalCapture>> watchCaptures() {
    return db.watchAllCaptures();
  }

  Future<LocalCapture> captureUrl(String url) async {
    final localId = _uuid.v4();
    final now = DateTime.now();

    final entry = LocalCapturesCompanion(
      id: Value(localId),
      originalUrl: Value(url),
      contentType: const Value('URL'),
      status: const Value('PENDING_SYNC'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    // 1. Optimistic Local SQLite Write (< 10ms)
    await db.insertCapture(entry);

    // 2. Immediate API Dispatch Attempt
    try {
      final response = await apiClient.createCapture(url);
      final data = response.data;

      if (response.statusCode == 200 && data != null) {
        // Cache Hit: Completed instantly ($0 AI cost)
        final serverId = data['id']?.toString();
        await db.updateCapture(
          LocalCapturesCompanion(
            id: Value(localId),
            serverCaptureId: Value(serverId),
            status: const Value('COMPLETED'),
            intent: Value(data['intent']?.toString()),
            category: Value(data['category']?.toString()),
            originalCaption: Value(data['original_caption']?.toString()),
            updatedAt: Value(DateTime.now()),
            syncedAt: Value(DateTime.now()),
          ),
        );
      } else if (response.statusCode == 202 && data != null) {
        // Cache Miss: Queued for async worker
        final serverId = data['id']?.toString();
        await db.updateCapture(
          LocalCapturesCompanion(
            id: Value(localId),
            serverCaptureId: Value(serverId),
            status: const Value('PROCESSING'),
            updatedAt: Value(DateTime.now()),
            syncedAt: Value(DateTime.now()),
          ),
        );
      }
    } catch (_) {
      // Offline / Network Failure: Stays PENDING_SYNC for background drain
    }

    return (await db.getCaptureById(localId))!;
  }

  Future<void> syncPending() async {
    final pendingList = await db.getPendingSyncCaptures();
    if (pendingList.isEmpty) return;

    for (final item in pendingList) {
      if (item.originalUrl != null && item.contentType == 'URL') {
        try {
          final response = await apiClient.createCapture(item.originalUrl!);
          final data = response.data;
          final serverId = data?['id']?.toString();
          final status = response.statusCode == 200 ? 'COMPLETED' : 'PROCESSING';

          await db.updateCapture(
            LocalCapturesCompanion(
              id: Value(item.id),
              serverCaptureId: Value(serverId),
              status: Value(status),
              intent: Value(data?['intent']?.toString()),
              category: Value(data?['category']?.toString()),
              updatedAt: Value(DateTime.now()),
              syncedAt: Value(DateTime.now()),
            ),
          );
        } catch (_) {
          // Will retry on next sync tick
        }
      }
    }
  }

  Future<void> fetchRemoteFeed({int page = 0, int size = 20}) async {
    try {
      final response = await apiClient.getCaptures(page: page, size: size);
      final items = response.data?['items'] as List<dynamic>?;

      if (items != null) {
        for (final raw in items) {
          if (raw is Map<String, dynamic>) {
            final serverId = raw['id']?.toString();
            if (serverId != null) {
              final existing = await db.getCaptureByServerId(serverId);
              final id = existing?.id ?? _uuid.v4();

              await db.insertCapture(
                LocalCapturesCompanion(
                  id: Value(id),
                  serverCaptureId: Value(serverId),
                  originalUrl: Value(raw['original_caption']?.toString()),
                  contentType: Value(raw['content_type']?.toString() ?? 'URL'),
                  status: Value(raw['status']?.toString() ?? 'COMPLETED'),
                  intent: Value(raw['intent']?.toString()),
                  category: Value(raw['category']?.toString()),
                  originalCaption: Value(raw['original_caption']?.toString()),
                  updatedAt: Value(DateTime.now()),
                  syncedAt: Value(DateTime.now()),
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
  }
}

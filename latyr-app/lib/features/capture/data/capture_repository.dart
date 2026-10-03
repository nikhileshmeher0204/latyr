import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/util/capture_source_classifier.dart';
import 'package:uuid/uuid.dart';

class CaptureRepository {
  final AppDatabase db;
  final ApiClient apiClient;
  final SseClient? sseClient;
  final Uuid _uuid = const Uuid();
  StreamSubscription<SseCaptureEvent>? _sseSubscription;

  CaptureRepository({
    required this.db,
    required this.apiClient,
    this.sseClient,
  }) {
    _initSseListener();
    db.deduplicateCaptures();
  }

  static String normalizeUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl.trim());
      const trackingParams = {
        'igsh', 'stkn', 'fbclid', 'si', 'ref', 'ref_src', 'feature', 'context',
        'mibextid', 'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content'
      };
      final cleanQuery = Map<String, String>.from(uri.queryParameters)
        ..removeWhere((k, _) => trackingParams.contains(k.toLowerCase()));

      var path = uri.path;
      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }

      final cleanUri = Uri(
        scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
        host: uri.host.replaceFirst(RegExp(r'^www\.'), ''),
        path: path,
        queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
      );
      return cleanUri.toString();
    } catch (_) {
      return rawUrl.trim();
    }
  }

  void _initSseListener() {
    _sseSubscription?.cancel();
    _sseSubscription = sseClient?.events.listen((event) async {
      final captureId = event.data['capture_id']?.toString();
      if (captureId == null) return;

      debugPrint('[CaptureRepo] Received SSE event ${event.eventType} for capture $captureId');

      if (event.eventType == 'CAPTURE_PROCESSING') {
        var existing = await db.getCaptureByServerId(captureId);
        final rawCaption = event.data['original_caption']?.toString();
        if (existing == null && rawCaption != null && rawCaption.isNotEmpty) {
          existing = await db.getCaptureByUrl(rawCaption);
        }
        if (existing != null && existing.status != 'PROCESSING') {
          await db.updateCapture(
            LocalCapturesCompanion(
              id: Value(existing.id),
              serverCaptureId: Value(captureId),
              status: const Value('PROCESSING'),
              updatedAt: Value(DateTime.now()),
            ),
          );
          debugPrint('[CaptureRepo] Updated capture ${existing.id} to PROCESSING via SSE');
        }
      } else if (event.eventType == 'CAPTURE_COMPLETED') {
        var existing = await db.getCaptureByServerId(captureId);
        final rawCaption = event.data['original_caption']?.toString();
        if (existing == null && rawCaption != null && rawCaption.isNotEmpty) {
          existing = await db.getCaptureByUrl(rawCaption);
        }

        final entities = event.data['entities'];
        final entitiesJson = entities != null ? jsonEncode(entities) : null;
        final intent = event.data['intent']?.toString();
        final category = event.data['category']?.toString();
        final summary = event.data['summary']?.toString();
        final title = event.data['title']?.toString();
        final transcript = event.data['audio_transcript']?.toString();
        final thumbnailUrl = event.data['thumbnail_url']?.toString();
        final sourceType = event.data['source_type']?.toString();

        if (existing != null) {
          await db.updateCapture(
            LocalCapturesCompanion(
              id: Value(existing.id),
              serverCaptureId: Value(captureId),
              status: const Value('COMPLETED'),
              sourceType: Value(
                sourceType ??
                    existing.sourceType ??
                    CaptureSourceClassifier.classify(
                      rawCaption ?? existing.originalUrl ?? existing.originalCaption,
                    )?.name.toUpperCase(),
              ),
              intent: Value(intent),
              category: Value(category),
              summary: Value(summary ?? existing.summary),
              title: Value(title ?? existing.title),
              originalCaption: Value(rawCaption ?? existing.originalCaption),
              thumbnailUrl: Value(thumbnailUrl ?? existing.thumbnailUrl),
              audioTranscript: Value(transcript),
              entitiesJson: Value(entitiesJson),
              updatedAt: Value(DateTime.now()),
              syncedAt: Value(DateTime.now()),
            ),
          );
          debugPrint('[CaptureRepo] Updated capture ${existing.id} to COMPLETED via SSE');
        } else {
          await db.insertCapture(
            LocalCapturesCompanion(
              id: Value(_uuid.v4()),
              serverCaptureId: Value(captureId),
              originalUrl: Value(rawCaption),
              sourceType: Value(sourceType ?? CaptureSourceClassifier.classify(rawCaption)?.name.toUpperCase()),
              contentType: const Value('URL'),
              status: const Value('COMPLETED'),
              intent: Value(intent),
              category: Value(category),
              summary: Value(summary),
              title: Value(title),
              originalCaption: Value(rawCaption),
              thumbnailUrl: Value(thumbnailUrl),
              audioTranscript: Value(transcript),
              entitiesJson: Value(entitiesJson),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
              syncedAt: Value(DateTime.now()),
            ),
          );
          debugPrint('[CaptureRepo] Inserted new capture $captureId to COMPLETED via SSE');
        }
      } else if (event.eventType == 'CAPTURE_FAILED') {
        final existing = await db.getCaptureByServerId(captureId);
        if (existing != null) {
          await db.updateCapture(
            LocalCapturesCompanion(
              id: Value(existing.id),
              serverCaptureId: Value(captureId),
              status: const Value('FAILED'),
              updatedAt: Value(DateTime.now()),
            ),
          );
          debugPrint('[CaptureRepo] Updated capture ${existing.id} to FAILED via SSE');
        }
      }
    });
  }

  void dispose() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  Stream<List<LocalCapture>> watchCaptures() {
    return db.watchAllCaptures();
  }

  Future<LocalCapture> captureUrl(String rawUrl, {String? caption}) async {
    final cleanUrl = normalizeUrl(rawUrl);
    debugPrint('Normalized capture URL: $cleanUrl');

    // 0. Check for existing local capture with this URL (or raw URL)
    final existingLocal = await db.getCaptureByUrl(cleanUrl) ??
        (rawUrl != cleanUrl ? await db.getCaptureByUrl(rawUrl) : null);

    if (existingLocal != null) {
      debugPrint('Existing local capture found for URL: ${existingLocal.id} (status: ${existingLocal.status})');
      // If already COMPLETED or PROCESSING, do not re-insert or double-process
      if (existingLocal.status == 'COMPLETED' || existingLocal.status == 'PROCESSING') {
        return existingLocal;
      }
    }

    final localId = existingLocal?.id ?? _uuid.v4();
    final now = DateTime.now();

    final detectedSource = CaptureSourceClassifier.classify(rawUrl) ??
        CaptureSourceClassifier.classify(cleanUrl);
    final initialSourceType = detectedSource?.name.toUpperCase();

    final entry = LocalCapturesCompanion(
      id: Value(localId),
      originalUrl: Value(rawUrl.trim()),
      sourceType: Value(initialSourceType),
      contentType: const Value('URL'),
      originalCaption: Value(caption ?? existingLocal?.originalCaption),
      status: const Value('PENDING_SYNC'),
      createdAt: Value(existingLocal?.createdAt ?? now),
      updatedAt: Value(now),
    );

    // 1. Optimistic Local SQLite Write (< 10ms)
    await db.insertCapture(entry);
    debugPrint('Optimistically saved capture to SQLite: $localId');

    // 2. Immediate API Dispatch Attempt
    try {
      debugPrint('Dispatching POST /api/v1/captures with url: $cleanUrl, caption: $caption');
      final response = await apiClient.createCapture(cleanUrl, caption: caption);
      final data = response.data;
      debugPrint('Server response status: ${response.statusCode}, body: $data');

      if ((response.statusCode == 200 || response.statusCode == 202) && data != null) {
        final serverId = data['id']?.toString();
        final serverStatus = data['status']?.toString();
        final serverSourceType = data['source_type']?.toString();
        final status = response.statusCode == 200 ? 'COMPLETED' : (serverStatus ?? 'PROCESSING');
        await db.updateCapture(
          LocalCapturesCompanion(
            id: Value(localId),
            serverCaptureId: Value(serverId),
            status: Value(status),
            sourceType: Value(serverSourceType ?? initialSourceType),
            intent: Value(data['intent']?.toString()),
            category: Value(data['category']?.toString()),
            originalCaption: Value(data['original_caption']?.toString() ?? caption),
            thumbnailUrl: Value(data['thumbnail_url']?.toString()),
            updatedAt: Value(DateTime.now()),
            syncedAt: Value(DateTime.now()),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('API Dispatch Error for capture $localId: $e');
      debugPrint('$st');
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
          debugPrint('Syncing pending capture: ${item.id}');
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
              thumbnailUrl: Value(data?['thumbnail_url']?.toString()),
              updatedAt: Value(DateTime.now()),
              syncedAt: Value(DateTime.now()),
            ),
          );
        } catch (e) {
          debugPrint('Sync pending failed for ${item.id}: $e');
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
        bool modified = false;
        for (final raw in items) {
          if (raw is Map<String, dynamic>) {
            final serverId = raw['id']?.toString();
            if (serverId != null) {
              var existing = await db.getCaptureByServerId(serverId);
              final rawCaption = raw['original_caption']?.toString();
              if (existing == null && rawCaption != null) {
                existing = await db.getCaptureByUrl(rawCaption);
              }
              final id = existing?.id ?? _uuid.v4();

              // If existing item lacks entities, fetch detail
              String? entitiesJson = existing?.entitiesJson;
              if (entitiesJson == null || entitiesJson.isEmpty) {
                try {
                  final detailResp = await apiClient.getCaptureDetail(serverId);
                  final detailData = detailResp.data;
                  if (detailData != null && detailData['entities'] != null) {
                    entitiesJson = jsonEncode(detailData['entities']);
                  }
                } catch (_) {}
              }

              final newStatus = raw['status']?.toString() ?? 'COMPLETED';
              final newSourceType = raw['source_type']?.toString() ??
                  CaptureSourceClassifier.classify(rawCaption)?.name.toUpperCase();
              final newIntent = raw['intent']?.toString();
              final newCategory = raw['category']?.toString(); final newSubCategory = raw['sub_category']?.toString(); final newSummary = raw['summary']?.toString();
              final newTitle = raw['title']?.toString();
              final rawTranscript = raw['audio_transcript']?.toString();
              final rawThumbnail = raw['thumbnail_url']?.toString();
              final serverCreatedAt = raw['created_at'] != null
                  ? DateTime.tryParse(raw['created_at'].toString())
                  : null;
              final serverUpdatedAt = raw['updated_at'] != null
                  ? DateTime.tryParse(raw['updated_at'].toString())
                  : null;

              if (existing != null) {
                final bool hasChanged = existing.serverCaptureId != serverId ||
                    existing.status != newStatus ||
                    existing.sourceType != newSourceType ||
                    existing.intent != newIntent ||
                    existing.category != newCategory || existing.subCategory != newSubCategory || existing.summary != newSummary ||
                    existing.title != newTitle ||
                    existing.originalCaption != rawCaption ||
                    existing.audioTranscript != rawTranscript ||
                    existing.thumbnailUrl != rawThumbnail ||
                    existing.entitiesJson != entitiesJson;

                if (!hasChanged) {
                  // No modifications to database row, skipping to prevent Drift stream emissions
                  continue;
                }

                modified = true;
                await db.updateCapture(
                  LocalCapturesCompanion(
                    id: Value(existing.id),
                    serverCaptureId: Value(serverId),
                    status: Value(newStatus),
                    sourceType: Value(newSourceType ?? existing.sourceType),
                    intent: Value(newIntent),
                    category: Value(newCategory), subCategory: Value(newSubCategory), summary: Value(newSummary),
                    title: Value(newTitle ?? existing.title),
                    originalCaption: Value(rawCaption),
                    thumbnailUrl: Value(rawThumbnail ?? existing.thumbnailUrl),
                    audioTranscript: Value(rawTranscript),
                    entitiesJson: Value(entitiesJson),
                    updatedAt: Value(serverUpdatedAt ?? existing.updatedAt),
                    syncedAt: Value(DateTime.now()),
                  ),
                );
              } else {
                modified = true;
                await db.insertCapture(
                  LocalCapturesCompanion(
                    id: Value(id),
                    serverCaptureId: Value(serverId),
                    originalUrl: Value(raw['original_caption']?.toString()),
                    sourceType: Value(newSourceType),
                    contentType: Value(raw['content_type']?.toString() ?? 'URL'),
                    status: Value(newStatus),
                    intent: Value(newIntent),
                    category: Value(newCategory), subCategory: Value(newSubCategory), summary: Value(newSummary),
                    title: Value(newTitle),
                    originalCaption: Value(rawCaption),
                    thumbnailUrl: Value(rawThumbnail),
                    audioTranscript: Value(rawTranscript),
                    entitiesJson: Value(entitiesJson),
                    createdAt: Value(serverCreatedAt ?? DateTime.now()),
                    updatedAt: Value(serverUpdatedAt ?? serverCreatedAt ?? DateTime.now()),
                    syncedAt: Value(DateTime.now()),
                  ),
                );
              }
            }
          }
        }
        if (modified) {
          await db.deduplicateCaptures();
        }
      }
    } catch (_) {}
  }

  Future<bool> hasActiveProcessingCaptures() async {
    final all = await db.getAllCaptures();
    return all.any((c) =>
        (c.status == 'PROCESSING' || c.status == 'PENDING' || c.status == 'PENDING_SYNC') &&
        c.serverCaptureId != null);
  }

  Future<void> checkProcessingCaptures() async {
    final all = await db.getAllCaptures();
    final processing = all
        .where((c) =>
            (c.status == 'PROCESSING' || c.status == 'PENDING' || c.status == 'PENDING_SYNC') &&
            c.serverCaptureId != null)
        .toList();
    if (processing.isEmpty) return;

    for (final item in processing) {
      try {
        final response = await apiClient.getCaptureDetail(item.serverCaptureId!);
        final data = response.data;
        if (data != null) {
          final serverStatus = data['status']?.toString();
          if (serverStatus == 'COMPLETED') {
            final entities = data['entities'];
            await db.updateCapture(
              LocalCapturesCompanion(
                id: Value(item.id),
                serverCaptureId: Value(item.serverCaptureId),
                status: const Value('COMPLETED'),
                intent: Value(data['intent']?.toString()),
                category: Value(data['category']?.toString()),
                title: Value(data['title']?.toString() ?? item.title),
                originalCaption: Value(data['original_caption']?.toString()),
                audioTranscript: Value(data['audio_transcript']?.toString()),
                entitiesJson: Value(entities != null ? jsonEncode(entities) : null),
                updatedAt: Value(DateTime.now()),
                syncedAt: Value(DateTime.now()),
              ),
            );
          } else if (serverStatus == 'PROCESSING' && item.status != 'PROCESSING') {
            await db.updateCapture(
              LocalCapturesCompanion(
                id: Value(item.id),
                serverCaptureId: Value(item.serverCaptureId),
                status: const Value('PROCESSING'),
                updatedAt: Value(DateTime.now()),
              ),
            );
          } else if (serverStatus == 'FAILED' && item.status != 'FAILED') {
            await db.updateCapture(
              LocalCapturesCompanion(
                id: Value(item.id),
                serverCaptureId: Value(item.serverCaptureId),
                status: const Value('FAILED'),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error polling capture ${item.serverCaptureId}: $e');
      }
    }
  }
}

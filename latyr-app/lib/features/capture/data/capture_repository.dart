import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/util/capture_source_classifier.dart';
import 'package:uuid/uuid.dart';

class CaptureRepository {
  final AppDatabase db;
  final ApiClient apiClient;
  final SseClient? sseClient;
  final bool Function() canCapture;
  final Uuid _uuid = const Uuid();
  StreamSubscription<SseCaptureEvent>? _sseSubscription;
  bool _disposed = false;
  bool _isSyncing = false;

  bool get _hasCaptureSession => !_disposed && canCapture();

  CaptureRepository({
    required this.db,
    required this.apiClient,
    required this.canCapture,
    this.sseClient,
  }) {
    _initSseListener();
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
      if (!_hasCaptureSession) return;
      try {
      final captureId = event.data['capture_id']?.toString();
      if (captureId == null) return;

      debugPrint('[CaptureRepo] Received SSE event ${event.eventType} for capture $captureId');

      if (event.eventType == 'CAPTURE_PROCESSING') {
        var existing = await db.getCaptureByServerId(captureId);
        if (!_hasCaptureSession) return;
        final rawCaption = event.data['original_caption']?.toString();
        if (existing == null && rawCaption != null && rawCaption.isNotEmpty) {
          existing = await db.getUniqueUnboundUrlCapture(rawCaption);
        }
        if (existing != null &&
            (existing.status == 'PENDING' || existing.status == 'PENDING_SYNC')) {
          if (!_hasCaptureSession) return;
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
        if (!_hasCaptureSession) return;
        final rawCaption = event.data['original_caption']?.toString();
        if (existing == null && rawCaption != null && rawCaption.isNotEmpty) {
          existing = await db.getUniqueUnboundUrlCapture(rawCaption);
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

        if (!_hasCaptureSession) return;
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
      } else if (event.eventType == 'ENTITY_ENRICHED') {
        final captureId = event.data['capture_id']?.toString();
        if (captureId != null) {
          final existing = await db.getCaptureByServerId(captureId);
          if (!_hasCaptureSession) return;
          if (existing != null) {
            try {
              final detailResp = await apiClient.getCaptureDetail(captureId);
              if (!_hasCaptureSession) return;
              final detailData = detailResp.data;
              if (detailData != null && detailData['entities'] != null) {
                await db.updateCapture(
                  LocalCapturesCompanion(
                    id: Value(existing.id),
                    entitiesJson: Value(jsonEncode(detailData['entities'])),
                    updatedAt: Value(DateTime.now()),
                  ),
                );
                debugPrint('[CaptureRepo] Updated capture ${existing.id} entities via ENTITY_ENRICHED SSE');
              }
            } catch (e) {
              debugPrint('[CaptureRepo] Failed to refresh entities on ENTITY_ENRICHED: $e');
            }
          }
        }
      } else if (event.eventType == 'CAPTURE_FAILED' ||
          event.eventType == 'CAPTURE_PARTIAL') {
        final existing = await db.getCaptureByServerId(captureId);
        if (!_hasCaptureSession) return;
        if (existing != null) {
          await db.updateCapture(
            LocalCapturesCompanion(
              id: Value(existing.id),
              serverCaptureId: Value(captureId),
              status: Value(event.eventType == 'CAPTURE_PARTIAL' ? 'PARTIAL' : 'FAILED'),
              updatedAt: Value(DateTime.now()),
            ),
          );
          debugPrint('[CaptureRepo] Applied terminal event ${event.eventType} to capture ${existing.id}');
        }
      }
      } catch (_) {
        if (_hasCaptureSession) debugPrint('Capture stream update could not be applied.');
      }
    });
  }

  void dispose() {
    _disposed = true;
    _sseSubscription?.cancel();
    _sseSubscription = null;
  }

  Stream<List<LocalCapture>> watchCaptures() {
    _requireCaptureSession();
    return db.watchAllCaptures();
  }

  Future<LocalCapture> captureUrl(String rawUrl, {String? caption}) async {
    _requireCaptureSession();
    final cleanUrl = normalizeUrl(rawUrl);
    debugPrint('Normalized capture URL: $cleanUrl');

    // 0. Check for existing local capture with this URL (or raw URL)
    final existingLocal = await db.getCaptureByUrl(cleanUrl) ??
        (rawUrl != cleanUrl ? await db.getCaptureByUrl(rawUrl) : null);

    if (existingLocal != null) {
      _requireCaptureSession();
      debugPrint('Existing local capture found for URL: ${existingLocal.id} (status: ${existingLocal.status})');
      // Completed/partial captures are immutable and must not be resubmitted.
      if (existingLocal.status == 'COMPLETED' ||
          existingLocal.status == 'PROCESSING' ||
          existingLocal.status == 'PARTIAL') {
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
    _requireCaptureSession();
    await db.insertCapture(entry);
    debugPrint('Optimistically saved capture to SQLite: $localId');

    // 2. Immediate API Dispatch Attempt
    try {
      debugPrint('Dispatching POST /api/v1/captures with url: $cleanUrl, caption: $caption');
      final response = await apiClient.createCapture(cleanUrl, caption: caption);
      _requireCaptureSession();
      final data = response.data;
      debugPrint('Server response status: ${response.statusCode}, body: $data');

      if ((response.statusCode == 200 || response.statusCode == 202) && data != null) {
        final serverId = data['id']?.toString();
        final serverStatus = data['status']?.toString();
        final serverSourceType = data['source_type']?.toString();
        final status = serverStatus ??
            (response.statusCode == 200 ? 'COMPLETED' : 'PROCESSING');
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

    _requireCaptureSession();
    final saved = await db.getCaptureById(localId);
    _requireCaptureSession();
    return saved!;
  }

  Future<void> syncPending() async {
    if (!_hasCaptureSession) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final pendingList = await db.getPendingSyncCaptures();
      if (pendingList.isEmpty) return;

      for (final item in pendingList) {
        if (!_hasCaptureSession) return;
        if (item.originalUrl != null && item.contentType == 'URL') {
          try {
            debugPrint('Syncing pending capture: ${item.id}');
            final response = await apiClient.createCapture(
              item.originalUrl!,
              caption: item.originalCaption,
            );
            if (!_hasCaptureSession) return;
            final data = response.data;
            final serverId = data?['id']?.toString();
            final serverStatus = data?['status']?.toString();
            final status = serverStatus ??
                (response.statusCode == 200 ? 'COMPLETED' : 'PROCESSING');

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
          } on DioException catch (e) {
            final statusCode = e.response?.statusCode;
            final errorCode = e.response?.data is Map ? e.response?.data['error']?.toString() : null;
            final errorMessage = e.response?.data is Map ? e.response?.data['message']?.toString() : null;
            debugPrint('Sync pending DioException for ${item.id}: status=$statusCode, error=$errorCode');

            if (statusCode == 400 || statusCode == 402) {
              await db.updateCapture(
                LocalCapturesCompanion(
                  id: Value(item.id),
                  status: const Value('FAILED'),
                  summary: Value(errorMessage ?? errorCode ?? 'Sync failed ($statusCode)'),
                  updatedAt: Value(DateTime.now()),
                ),
              );
            } else if (statusCode == 401 || statusCode == 403) {
              return;
            }
          } catch (e) {
            debugPrint('Sync pending unexpected error for ${item.id}: $e');
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _requireCaptureSession() {
    if (!_hasCaptureSession) throw const AuthenticationRequiredException();
  }

  Future<void> fetchRemoteFeed({
    int page = 0,
    int size = 20,
    bool hydrateAll = false,
    int maxPages = 10,
  }) async {
    if (!_hasCaptureSession) return;
    try {
      int currentPage = page;
      bool hasMore = true;
      int pagesFetched = 0;

      while (hasMore && pagesFetched < maxPages) {
        final response = await apiClient.getCaptures(page: currentPage, size: size);
        if (!_hasCaptureSession) return;
        final data = response.data;
        final items = data?['items'] as List<dynamic>?;
        final totalPages = data?['total_pages'] as int? ?? 1;
        pagesFetched++;

        if (items != null && items.isNotEmpty) {
          for (final raw in items) {
            if (!_hasCaptureSession) return;
            if (raw is Map<String, dynamic>) {
              final serverId = raw['id']?.toString();
              if (serverId != null) {
                var existing = await db.getCaptureByServerId(serverId);
                if (!_hasCaptureSession) return;
                final rawCaption = raw['original_caption']?.toString();
                if (existing == null && rawCaption != null) {
                  existing = await db.getUniqueUnboundUrlCapture(rawCaption);
                }
                final id = existing?.id ?? _uuid.v4();

                final serverUpdatedAt = raw['updated_at'] != null
                    ? DateTime.tryParse(raw['updated_at'].toString())
                    : null;

                String? entitiesJson = existing?.entitiesJson;
                if (raw['entities'] != null) {
                  entitiesJson = jsonEncode(raw['entities']);
                }

                final newStatus = raw['status']?.toString() ?? 'COMPLETED';
                final newSourceType = raw['source_type']?.toString() ??
                    CaptureSourceClassifier.classify(rawCaption)?.name.toUpperCase();
                final newIntent = raw['intent']?.toString();
                final newCategory = raw['category']?.toString();
                final newSubCategory = raw['sub_category']?.toString();
                final newSummary = raw['summary']?.toString();
                final newTitle = raw['title']?.toString();
                final rawTranscript = raw['audio_transcript']?.toString();
                final rawThumbnail = raw['thumbnail_url']?.toString();
                final serverCreatedAt = raw['created_at'] != null
                    ? DateTime.tryParse(raw['created_at'].toString())
                    : null;

                if (!_hasCaptureSession) return;
                if (existing != null) {
                  final bool hasChanged = existing.serverCaptureId != serverId ||
                      existing.status != newStatus ||
                      existing.sourceType != newSourceType ||
                      existing.intent != newIntent ||
                      existing.category != newCategory ||
                      existing.subCategory != newSubCategory ||
                      existing.summary != newSummary ||
                      existing.title != newTitle ||
                      existing.originalCaption != rawCaption ||
                      existing.audioTranscript != rawTranscript ||
                      existing.thumbnailUrl != rawThumbnail ||
                      existing.entitiesJson != entitiesJson;

                  if (!hasChanged) {
                    continue;
                  }

                  await db.updateCapture(
                    LocalCapturesCompanion(
                      id: Value(existing.id),
                      serverCaptureId: Value(serverId),
                      status: Value(newStatus),
                      sourceType: Value(newSourceType ?? existing.sourceType),
                      intent: Value(newIntent),
                      category: Value(newCategory),
                      subCategory: Value(newSubCategory),
                      summary: Value(newSummary),
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
                  await db.insertCapture(
                    LocalCapturesCompanion(
                      id: Value(id),
                      serverCaptureId: Value(serverId),
                      originalUrl: Value(raw['original_caption']?.toString()),
                      sourceType: Value(newSourceType),
                      contentType: Value(raw['content_type']?.toString() ?? 'URL'),
                      status: Value(newStatus),
                      intent: Value(newIntent),
                      category: Value(newCategory),
                      subCategory: Value(newSubCategory),
                      summary: Value(newSummary),
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
        }

        if (hydrateAll && currentPage + 1 < totalPages) {
          currentPage++;
        } else {
          hasMore = false;
        }
      }
    } catch (_) {}
  }

  Future<bool> hasActiveProcessingCaptures() async {
    if (!_hasCaptureSession) return false;
    final all = await db.getAllCaptures();
    if (!_hasCaptureSession) return false;
    return all.any((c) =>
        (c.status == 'PROCESSING' || c.status == 'PENDING' || c.status == 'PENDING_SYNC') &&
        c.serverCaptureId != null);
  }

  Future<void> checkProcessingCaptures() async {
    if (!_hasCaptureSession) return;
    final all = await db.getAllCaptures();
    final processing = all
        .where((c) =>
            (c.status == 'PROCESSING' || c.status == 'PENDING' || c.status == 'PENDING_SYNC') &&
            c.serverCaptureId != null)
        .toList();
    if (processing.isEmpty) return;

    for (final item in processing) {
      if (!_hasCaptureSession) return;
      try {
        final response = await apiClient.getCaptureDetail(item.serverCaptureId!);
        if (!_hasCaptureSession) return;
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
          } else if ((serverStatus == 'FAILED' || serverStatus == 'PARTIAL') &&
              item.status != serverStatus) {
            await db.updateCapture(
              LocalCapturesCompanion(
                id: Value(item.id),
                serverCaptureId: Value(item.serverCaptureId),
                status: Value(serverStatus!),
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

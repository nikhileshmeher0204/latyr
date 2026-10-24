import 'dart:typed_data';
import 'package:dio/dio.dart';

class RecordingHttpAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final ResponseBody Function(RequestOptions)? respond;
  RecordingHttpAdapter({this.respond});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond?.call(options) ??
        ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

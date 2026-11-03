import 'dart:convert';
import 'dart:io';
import 'http_transport.dart';

class PlatformHttpTransport implements HttpTransport {
  const PlatformHttpTransport();

  @override
  Future<HttpResponseData> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String jsonBody,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final request = await client.postUrl(uri).timeout(timeout);
      headers.forEach((k, v) => request.headers.set(k, v));
      request.headers.contentType = ContentType.json;

      request.write(jsonBody);
      final response = await request.close().timeout(timeout);

      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      return HttpResponseData(
        statusCode: response.statusCode,
        body: body,
      );
    } finally {
      client.close();
    }
  }
}

HttpTransport createDefaultHttpTransport() => const PlatformHttpTransport();


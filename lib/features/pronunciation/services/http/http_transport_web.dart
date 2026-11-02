// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
    final req = await html.HttpRequest.request(
      uri.toString(),
      method: 'POST',
      sendData: jsonBody,
      requestHeaders: {
        'Content-Type': 'application/json',
        ...headers,
      },
    ).timeout(timeout);

    return HttpResponseData(
      statusCode: req.status ?? 0,
      body: req.responseText ?? '',
    );
  }
}

HttpTransport createDefaultHttpTransport() => const PlatformHttpTransport();

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'http_transport.dart';

class PlatformHttpTransport implements HttpTransport {
  const PlatformHttpTransport();

  @override
  Future<HttpResponseData> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String jsonBody,
    Duration timeout = const Duration(seconds: 120),
  }) {
    final controller = web.AbortController();
    final requestHeaders = web.Headers()
      ..set('Content-Type', 'application/json');
    headers.forEach((name, value) => requestHeaders.set(name, value));
    return (() async {
      final response = await web.window
          .fetch(
            uri.toString().toJS,
            web.RequestInit(
              method: 'POST',
              headers: requestHeaders,
              body: jsonBody.toJS,
              signal: controller.signal,
            ),
          )
          .toDart;
      return HttpResponseData(
        statusCode: response.status,
        body: (await response.text().toDart).toDart,
      );
    })().timeout(
      timeout,
      onTimeout: () {
        controller.abort();
        throw TimeoutException('Backend request timed out', timeout);
      },
    );
  }
}

HttpTransport createDefaultHttpTransport() => const PlatformHttpTransport();

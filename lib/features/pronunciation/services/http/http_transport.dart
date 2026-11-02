class HttpResponseData {
  const HttpResponseData({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;
}

abstract interface class HttpTransport {
  Future<HttpResponseData> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required String jsonBody,
    Duration timeout = const Duration(seconds: 12),
  });
}

import 'http_transport.dart';
import 'http_transport_stub.dart'
    if (dart.library.io) 'http_transport_mobile.dart'
    if (dart.library.html) 'http_transport_web.dart';

export 'http_transport.dart';

HttpTransport getHttpTransport() => createDefaultHttpTransport();

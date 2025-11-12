import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  
  static Future<void> initialize(Function(Uri) onLink) async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      onLink(initialUri);
    }
    
    _appLinks.uriLinkStream.listen((uri) {
      onLink(uri);
    });
  }
  
  static void handleDeepLink(Uri uri) {
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'product') {
      final productId = uri.pathSegments[1];
    }
  }
}
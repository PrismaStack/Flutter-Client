/// config.dart
///
/// Central place to set your backend/server domain and websocket host.
/// Update these values to change between dev, staging, or production.

class AppConfig {
  // Use the domain without trailing slash, e.g. http://localhost:8080 or https://myserver.com
//  static const String apiDomain = "https://chat.sarahsforge.dev:443";
//  static const String wsDomain = "wss://chat.sarahsforge.dev:443";
  static const String apiDomain = "http://192.168.254.19:8081";
  static const String wsDomain = "ws://192.168.254.19:8081";
}
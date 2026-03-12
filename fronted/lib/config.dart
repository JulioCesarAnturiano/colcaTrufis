/// API base URL configuration.
/// Override at build time with --dart-define:
///   flutter build apk --dart-define=API_BASE_URL=http://192.168.x.x:8000/api
///
/// Default: http://10.0.2.2:8000/api (Android emulator loopback to host machine)
/// For physical devices on the same Wi-Fi network use your machine's LAN IP instead.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);

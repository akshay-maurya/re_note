class GlobalServices {
  static final GlobalServices _instance = GlobalServices._internal();
  factory GlobalServices() => _instance;
  GlobalServices._internal();

  static const String appName = 'Re:Note';
  static const String appVersion = '1.0.0';
}

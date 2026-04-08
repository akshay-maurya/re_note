class GlobalServices {
  static final GlobalServices _instance = GlobalServices._internal();
  factory GlobalServices() => _instance;
  GlobalServices._internal();

  static const String appName = 'Re:Note';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Re:Note is a note-taking app that allows you to take notes and sync them with your Google Drive.';
}
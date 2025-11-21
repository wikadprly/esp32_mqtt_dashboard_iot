// Default configuration for the MQTT IoT App
class AppConfig {
  // MQTT Settings
  static const String defaultBroker = 'broker.emqx.io';
  static const int defaultPort = 1883;
  static const String defaultUsername = 'emqx';
  static const String defaultPassword = 'public';
  static const String defaultClientId = 'flutter-client';
  static const int defaultKeepAlive = 60;
  
  // Sensor thresholds for recommendations
  static double temperatureHighThreshold = 35.0;
  static double temperatureLowThreshold = 18.0;
  static double humidityHighThreshold = 80.0;
  static double humidityLowThreshold = 30.0;
  
  // Default NIM
  static String defaultNim = '33424225';
}
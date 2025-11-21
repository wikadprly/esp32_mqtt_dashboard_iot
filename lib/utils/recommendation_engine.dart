class RecommendationEngine {
  // Default thresholds
  static double temperatureHighThreshold = 35.0;
  static double temperatureLowThreshold = 18.0;
  static double humidityHighThreshold = 80.0;
  static double humidityLowThreshold = 30.0;

  static List<String> getRecommendations(double temperature, double humidity) {
    List<String> recommendations = [];

    // Temperature recommendations
    if (temperature >= temperatureHighThreshold) {
      recommendations.add("High temperature detected (${temperature}°C) — consider turning on cooling");
    } else if (temperature <= temperatureLowThreshold) {
      recommendations.add("Low temperature detected (${temperature}°C) — consider checking heating or insulation");
    }

    // Humidity recommendations
    if (humidity >= humidityHighThreshold) {
      recommendations.add("High humidity detected (${humidity}%) — risk of condensation; consider dehumidifying");
    } else if (humidity <= humidityLowThreshold) {
      recommendations.add("Low humidity detected (${humidity}%) — may cause dryness; consider humidifier");
    }

    return recommendations;
  }

  // Method to update thresholds (would typically come from settings)
  static void updateThresholds({
    double? tempHigh,
    double? tempLow,
    double? humidityHigh,
    double? humidityLow,
  }) {
    if (tempHigh != null) temperatureHighThreshold = tempHigh;
    if (tempLow != null) temperatureLowThreshold = tempLow;
    if (humidityHigh != null) humidityHighThreshold = humidityHigh;
    if (humidityLow != null) humidityLowThreshold = humidityLow;
  }
}
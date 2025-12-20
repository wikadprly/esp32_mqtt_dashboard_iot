class RecommendationEngine {
  // Default thresholds
  static double temperatureHighThreshold = 35.0;
  static double temperatureLowThreshold = 18.0;
  static double humidityHighThreshold = 80.0;
  static double humidityLowThreshold = 30.0;
  static double lumenHighThreshold = 1000.0;  // High light intensity
  static double lumenLowThreshold = 50.0;     // Low light intensity

  static List<String> getRecommendations(double temperature, double humidity, {double lumen = 0.0}) {
    List<String> recommendations = [];

    // Temperature recommendations
    if (temperature >= temperatureHighThreshold) {
      recommendations.add("High temperature detected ($temperature°C) — consider turning on cooling");
    } else if (temperature <= temperatureLowThreshold) {
      recommendations.add("Low temperature detected ($temperature°C) — consider checking heating or insulation");
    }

    // Humidity recommendations
    if (humidity >= humidityHighThreshold) {
      recommendations.add("High humidity detected ($humidity%) — risk of condensation; consider dehumidifying");
    } else if (humidity <= humidityLowThreshold) {
      recommendations.add("Low humidity detected ($humidity%) — may cause dryness; consider humidifier");
    }

    // Lumen recommendations (optional, since older version might not pass lumen value)
    if (lumen > 0) { // Only if lumen value is provided
      if (lumen >= lumenHighThreshold) {
        recommendations.add("High lumen detected ($lumen lux) — consider reducing light intensity or using blinds");
      } else if (lumen <= lumenLowThreshold) {
        recommendations.add("Low lumen detected ($lumen lux) — consider increasing light intensity");
      }
    }

    return recommendations;
  }

  // Method to update thresholds (would typically come from settings)
  static void updateThresholds({
    double? tempHigh,
    double? tempLow,
    double? humidityHigh,
    double? humidityLow,
    double? lumenHigh,
    double? lumenLow,
  }) {
    if (tempHigh != null) temperatureHighThreshold = tempHigh;
    if (tempLow != null) temperatureLowThreshold = tempLow;
    if (humidityHigh != null) humidityHighThreshold = humidityHigh;
    if (humidityLow != null) humidityLowThreshold = humidityLow;
    if (lumenHigh != null) lumenHighThreshold = lumenHigh;
    if (lumenLow != null) lumenLowThreshold = lumenLow;
  }
}
# MQTT IoT Application

A Flutter application that connects to an MQTT broker, subscribes and publishes to specific topics for an ESP32-based IoT system, logs sensor data locally in SQLite, and shows a dashboard with history and recommendations.

## Features

- User authentication with MQTT broker
- MQTT connectivity with configurable settings
- Automatic reconnect on network drop
- Subscribe to temperature and humidity topics
- Publish control messages to control ESP32 LED
- Dashboard with sensor data visualization
- Local history of sensor messages in SQLite
- Time-series charts for temperature and humidity
- Basic rule engine for recommendations
- Device control UI
- Offline-first approach with local caching
- Developer logs and CSV export

## Technology Stack

- **Client:** Flutter (Dart)
- **Local DB:** sqflite (SQLite for Flutter)
- **MQTT:** mqtt_client Dart package
- **Charts:** charts_flutter
- **State management:** Provider

## MQTT Topics & Payloads

The application uses the format `polines/{nim}/...` where `{nim}` is the student identifier.

### ESP32 to Broker (Subscribed by App)
- `polines/{nim}/data/sensor/suhu` — Temperature value as numeric (e.g., `30`)
- `polines/{nim}/data/sensor/humidity` — Humidity value as numeric percentage (e.g., `60`)

### App to Broker to ESP32 (Published by App)
- `polines/{nim}/data/led` — LED control: `1` for ON, `0` for OFF

## Setup Instructions

1. Make sure you have Flutter installed on your system
2. Clone or download this project
3. Navigate to the project directory
4. Run the following commands:

```bash
flutter clean
flutter pub get
flutter run
```

## Default MQTT Settings

- Server: `broker.emqx.io`
- Port: `1883`
- Username: `emqx`
- Password: `public`
- NIM: `33424225` (default, can be changed in settings)

## Usage

1. On first launch, enter your MQTT credentials and NIM
2. Connect to the MQTT broker
3. The app will automatically subscribe to sensor topics
4. View sensor data on the dashboard
5. Control ESP32 LED using the control buttons
6. View detailed charts and history in the sensor detail screens
7. Check recommendations based on sensor values

## Testing with Desktop MQTT Client

Subscribe to topics:
- `polines/{nim}/data/sensor/suhu`
- `polines/{nim}/data/sensor/humidity`

Publish for control:
- Topic: `polines/{nim}/data/led`, Payload: `1` or `0`

## Project Structure

```
lib/
├── main.dart           # Entry point of the application
├── models/
│   ├── sensor_data.dart # Sensor data model
│   └── command.dart     # Command model
├── providers/
│   ├── mqtt_provider.dart   # MQTT service provider
│   └── database_provider.dart # Database service provider
├── screens/
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── device_control_screen.dart
│   ├── logs_screen.dart
│   ├── sensor_detail_screen.dart
│   └── sensor_chart.dart
└── utils/
    └── recommendation_engine.dart # Recommendation engine
```

## Database Schema

The application uses SQLite with the following tables:

- `users`: For local user storage
- `sensor_data`: Main time-series storage for sensor readings
- `commands`: Publish history and queued commands
- `settings`: App preferences and thresholds

## Recommendations

The app provides simple recommendations based on sensor thresholds:
- Temperature > 35°C: Suggest cooling
- Temperature < 18°C: Suggest checking heating
- Humidity > 80%: Suggest dehumidifying
- Humidity < 30%: Suggest using humidifier
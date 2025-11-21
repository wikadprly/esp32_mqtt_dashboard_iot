# Project Information

## MQTT IoT Application

This project is an MQTT-based IoT application built with Flutter that:
- Connects to an MQTT broker and subscribes to sensor topics
- Publishes control messages to control ESP32 devices
- Stores sensor data locally in SQLite
- Displays sensor history with charts and recommendations
- Implements offline-first principles

## Features Implemented

1. MQTT connectivity with configurable settings
2. Automatic reconnection with exponential backoff
3. Real-time sensor data visualization
4. Local data storage in SQLite
5. Basic recommendation engine
6. Device control interface
7. Data export capabilities
8. Responsive UI with status indicators

## Files Created

- `pubspec.yaml` - Project dependencies
- `lib/main.dart` - Application entry point
- `lib/providers/` - State management providers (MQTT and Database)
- `lib/screens/` - UI screens (Login, Dashboard, Control, Logs, etc.)
- `lib/models/` - Data models (SensorData, Command)
- `lib/services/` - Data handling services
- `lib/utils/` - Utility classes (Recommendation engine)
- `lib/config.dart` - Configuration constants
- `README.md` - Project documentation
- `test/main_test.dart` - Basic tests

## How to Run

1. Make sure you have Flutter installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Default Settings

- MQTT Broker: broker.emqx.io
- Port: 1883
- Username: emqx
- Password: public
- Default NIM: 33424225

## MQTT Topics

- Temperature: `polines/{nim}/data/sensor/suhu`
- Humidity: `polines/{nim}/data/sensor/humidity`
- LED Control: `polines/{nim}/data/led`

## Author

Generated from tech_spec_document.txt
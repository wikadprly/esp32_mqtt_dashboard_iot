import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/command.dart';
import '../providers/database_provider.dart';

class DataService {
  final DatabaseProvider databaseProvider;

  DataService(this.databaseProvider);

  // Parse incoming MQTT message and store if it's sensor data
  Future<void> parseAndStoreMessage(String topic, String payload) async {
    if (topic.contains('/data/sensor/')) {
      await _parseAndStoreSensorData(topic, payload);
    } else if (topic.contains('/data/led')) {
      await _parseAndStoreCommand(topic, payload, 'received');
    }
  }

  Future<void> _parseAndStoreSensorData(String topic, String payload) async {
    try {
      double value = double.parse(payload);
      String sensorType = topic.contains('/suhu') ? 'suhu' : 
                         topic.contains('/humidity') ? 'humidity' : 'unknown';
      
      if (sensorType != 'unknown') {
        SensorData sensorData = SensorData(
          topic: topic,
          sensorType: sensorType,
          value: value,
          timestamp: DateTime.now(),
        );
        
        await databaseProvider.insertSensorData(sensorData);
      }
    } catch (e) {
      debugPrint('Error parsing sensor data: $e');
    }
  }

  Future<void> storeCommand(String topic, String payload, String status) async {
    try {
      Command command = Command(
        topic: topic,
        payload: payload,
        status: status,
        createdAt: DateTime.now(),
      );

      await databaseProvider.insertCommand(command);
    } catch (e) {
      debugPrint('Error storing command: $e');
    }
  }

  Future<void> _parseAndStoreCommand(String topic, String payload, String status) async {
    await storeCommand(topic, payload, status);
  }
}
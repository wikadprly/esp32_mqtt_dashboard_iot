class SensorData {
  final int? id;
  final String topic;
  final String sensorType; // 'suhu' or 'humidity'
  final double value;
  final DateTime timestamp;

  SensorData({
    this.id,
    required this.topic,
    required this.sensorType,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic': topic,
      'sensor_type': sensorType,
      'value': value,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      id: map['id'],
      topic: map['topic'],
      sensorType: map['sensor_type'],
      value: map['value'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }
}
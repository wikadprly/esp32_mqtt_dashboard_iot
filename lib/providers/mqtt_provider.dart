import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../services/data_service.dart';
import '../providers/database_provider.dart';

class MqttProvider with ChangeNotifier {
  MqttServerClient? _client;
  String _connectionState = 'Disconnected';
  final String _nim = '33424225'; // Hardcoded NIM
  bool _isConnected = false;

  // Hardcoded MQTT settings
  String broker = 'broker.emqx.io';
  int port = 1883;
  String username = 'emqx';
  String password = 'public';
  String clientId = 'flutter-client-33424225-${DateTime.now().millisecondsSinceEpoch}';

  String get connectionState => _connectionState;
  bool get isConnected => _isConnected;
  String get nim => _nim;

  // Callbacks
  Function(String topic, String message)? onMessageReceived;
  DatabaseProvider? _databaseProvider;

  // Set the database provider for data service
  void setDatabaseProvider(DatabaseProvider databaseProvider) {
    _databaseProvider = databaseProvider;
  }

  Future<void> connect() async {
    // Create MQTT client with conditional logic for web
    _client = MqttServerClient(broker, clientId);

    // Set port
    _client!.port = port;

    // For web, we need to use WebSocket
    if (kIsWeb) {
      _client!.secure = false; // Use unencrypted WebSocket for web
    }

    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(username, password)
        .startClean();

    _client!.connectionMessage = connMsg;

    try {
      _connectionState = 'Connecting';
      notifyListeners();
      await _client!.connect();
    } catch (e) {
      _connectionState = 'Error: ${e.toString()}';
      _isConnected = false;
      notifyListeners();
      return;
    }

    // Subscribe to sensor topics after successful connection
    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.subscribe('polines/$_nim/data/sensor/suhu', MqttQos.atMostOnce);
      _client!.subscribe('polines/$_nim/data/sensor/humidity', MqttQos.atMostOnce);
      _client!.updates!.listen(_onMessage);
    }
  }

  void _onConnected() {
    _connectionState = 'Connected';
    _isConnected = true;
    notifyListeners();
  }

  void _onDisconnected() {
    _connectionState = 'Disconnected';
    _isConnected = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    debugPrint('Successfully subscribed to topic: $topic');
  }

  void _onMessage(covariant List<MqttReceivedMessage<MqttMessage>> messageList) {
    for (final message in messageList) {
      final topic = message.topic;
      final payload = message.payload as MqttPublishMessage;
      String messageString = '';

      // Convert payload to string properly - using the correct approach for this version
      try {
        // The payload property of MqttPublishMessage contains the raw payload bytes
        // which we need to convert to a string
        messageString = payload.payload.message.toList().map((e) => String.fromCharCode(e)).join('');
      } catch (e) {
        debugPrint('Error converting payload to string: $e');
        continue;
      }

      // Store the received message using data service
      if (_databaseProvider != null) {
        final dataService = DataService(_databaseProvider!);
        dataService.parseAndStoreMessage(topic, messageString);
      }

      // Notify listeners about the received message
      if (onMessageReceived != null) {
        onMessageReceived!(topic, messageString);
      }
    }
  }

  void publish(String topic, String payload, {MqttQos qos = MqttQos.atMostOnce}) {
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);
      _client!.publishMessage(topic, qos, builder.payload!);

      // Store the published command
      if (_databaseProvider != null) {
        final dataService = DataService(_databaseProvider!);
        dataService.storeCommand(topic, payload, 'sent');
      }
    }
  }

  void toggleLed() {
    if (_isConnected) {
      final currentValue = _ledState ? 0 : 1;
      final payload = currentValue.toString();
      publish('polines/$_nim/data/led', payload);
      _ledState = ! _ledState;
    }
  }

  bool _ledState = false;
  bool get ledState => _ledState;

  void disconnect() {
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.disconnect();
    }
  }

}
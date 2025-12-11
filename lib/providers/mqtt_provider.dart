import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../services/data_service.dart';
import '../providers/database_provider.dart';

class MqttProvider with ChangeNotifier {
  MqttServerClient? _client;
  String _connectionState = 'Disconnected';
  final String _nim = '33424225';
  bool _isConnected = false;

  // ============================
  // MQTT CONFIG FOR RASPBERRY PI
  // ============================
  String broker = '10.247.21.137'; // NEW: Local MQTT Broker
  int port = 1883;
  String username = 'wika'; // NEW
  String password = 'raspi'; // NEW
  String clientId =
      'flutter-client-33424225-${DateTime.now().millisecondsSinceEpoch}';

  String get connectionState => _connectionState;
  bool get isConnected => _isConnected;
  String get nim => _nim;

  Function(String topic, String message)? onMessageReceived;
  DatabaseProvider? _databaseProvider;

  // Set Database Provider
  void setDatabaseProvider(DatabaseProvider databaseProvider) {
    _databaseProvider = databaseProvider;
  }

  // =======================================
  // CONNECT TO MQTT BROKER (LOCAL NETWORK)
  // =======================================
  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;

    // Only for web: force websocket (ESP tidak pakai)
    if (kIsWeb) {
      _client!.secure = false;
      _client!.useWebSocket = true;
    }

    _client!
      ..logging(on: false)
      ..keepAlivePeriod = 60
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed;

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
      _connectionState = 'Error: $e';
      _isConnected = false;
      notifyListeners();
      return;
    }

    if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
      // Subscribe topics sesuai Arduino
      _client!.subscribe('polines/$_nim/data/sensor/suhu', MqttQos.atMostOnce);
      _client!
          .subscribe('polines/$_nim/data/sensor/humidity', MqttQos.atMostOnce);
      _client!.subscribe('iot/status', MqttQos.atMostOnce);

      _client!.updates!.listen(_onMessage);
    }
  }

  // EVENT CALLBACKS
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
    debugPrint('Subscribed to $topic');
  }

  // ==============================
  // HANDLE INCOMING MQTT MESSAGES
  // ==============================
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messageList) {
    for (final msg in messageList) {
      final topic = msg.topic;
      final payload = msg.payload as MqttPublishMessage;

      String messageString = String.fromCharCodes(
        payload.payload.message,
      );

      // Store into database
      if (_databaseProvider != null) {
        final dataService = DataService(_databaseProvider!);
        dataService.parseAndStoreMessage(topic, messageString);
      }

      // Callback to UI
      onMessageReceived?.call(topic, messageString);
    }
  }

  // =======================
  // PUBLISH DATA TO MQTT
  // =======================
  void publish(String topic, String payload,
      {MqttQos qos = MqttQos.atMostOnce}) {
    if (_client == null ||
        _client!.connectionStatus!.state != MqttConnectionState.connected) {
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(topic, qos, builder.payload!);

    if (_databaseProvider != null) {
      final dataService = DataService(_databaseProvider!);
      dataService.storeCommand(topic, payload, 'sent');
    }
  }

  // =======================
  // TOGGLE LED FOR ESP32
  // =======================
  bool _ledState = false;
  bool get ledState => _ledState;

  void toggleLed() {
    if (!_isConnected) return;

    final nextState = _ledState ? "0" : "1";

    publish('polines/$_nim/data/led', nextState);
    _ledState = !_ledState;

    notifyListeners();
  }

  // DISCONNECT CLIENT
  void disconnect() {
    if (_client != null &&
        _client!.connectionStatus!.state == MqttConnectionState.connected) {
      _client!.disconnect();
    }
  }
}

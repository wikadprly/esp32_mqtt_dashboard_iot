import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../services/data_service.dart';
import '../providers/database_provider.dart';

// ====================================
// ROLE
// ====================================
enum MqttUserRole { student, admin }

class MqttProvider with ChangeNotifier {
  MqttServerClient? _client;
  String _connectionState = 'Disconnected';
  bool _isConnected = false;

  final String _nim = "33424225"; // SESUAI KODE ESP MU
  MqttUserRole _role = MqttUserRole.student;

  MqttUserRole get role => _role;

  // ====================================
  // MQTT CONFIG — HARUS MATCH DENGAN ESP32
  // ====================================
  String broker = "10.33.29.218";
  int port = 1883;
  String username = "uas25_wika";   // MATCH ESP32
  String password = "uas25_wika";   // MATCH ESP32

  String get _defaultClientId => "flutter-client-33424225-${DateTime.now().millisecondsSinceEpoch}";
  final String _clientId = "";

  String get clientId => _clientId.isEmpty ? _defaultClientId : _clientId;

  String get connectionState => _connectionState;
  bool get isConnected => _isConnected;
  String get nim => _nim;

  // ====================================
  // TOPIC — MATCH EXACT ESP32
  // ====================================
  String get suhuTopic => "UAS25-IOT/$_nim/SUHU";
  String get kelembapanTopic => "UAS25-IOT/$_nim/KELEMBAPAN";
  String get lumenTopic => "UAS25-IOT/$_nim/LUMEN";

  // CONTROL TOPIC
  String get statusControlTopic => "UAS25-IOT/Status"; // START / STOP
  String get ledControlTopic => "UAS25-IOT/$_nim/LED"; // 1 / 0

  // Callback untuk UI
  Function(String topic, String message)? onMessageReceived;

  DatabaseProvider? _databaseProvider;
  void setDatabaseProvider(DatabaseProvider db) {
    _databaseProvider = db;
  }

  // ====================================
  // SET ROLE (student / admin)
  // ====================================
  void setUserRole(MqttUserRole role) {
    _role = role;

    // Jika admin → tidak boleh publish
    if (role == MqttUserRole.admin) {
      username = "uas26_admin";
      password = "uas26_admin";
    } else {
      username = "uas25_wika";     // student harus match dengan ESP32 ACL
      password = "uas25_wika";
    }

    notifyListeners();
  }

  // ====================================
  // CONNECT
  // ====================================
  Future<void> connect() async {
    _connectionState = "Connecting...";
    notifyListeners();

    try {
      _client = MqttServerClient(broker, clientId);
      _client!.port = port;

      if (kIsWeb) {
        _client!.useWebSocket = true;
        _client!.secure = false;
      }

      _client!
        ..keepAlivePeriod = 60
        ..logging(on: false)
        ..autoReconnect = true  // Enable automatic reconnection
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..onAutoReconnected = _onAutoReconnected;

      final connMsg = MqttConnectMessage()
          .authenticateAs(username, password)
          .withClientIdentifier(clientId)
          .startClean();

      _client!.connectionMessage = connMsg;

      await _client!.connect();
    } catch (e) {
      _connectionState = "Connection failed: ${e.toString()}";
      _isConnected = false;
      notifyListeners();
      debugPrint("MQTT Connection error: $e");
      return;
    }

    if (_client!.connectionStatus!.state ==
        MqttConnectionState.connected) {
      _connectionState = "Connected";
      _isConnected = true;

      // SUBSCRIBE semua topic
      try {
        _client!.subscribe(suhuTopic, MqttQos.atMostOnce);
        _client!.subscribe(kelembapanTopic, MqttQos.atMostOnce);
        _client!.subscribe(lumenTopic, MqttQos.atMostOnce);
        _client!.subscribe(statusControlTopic, MqttQos.atMostOnce);
        _client!.subscribe(ledControlTopic, MqttQos.atMostOnce);

        debugPrint("Successfully subscribed to all topics");
      } catch (e) {
        debugPrint("Subscription error: $e");
      }

      _client!.updates!.listen(_onMessage);
      notifyListeners();
    } else {
      _connectionState = "Failed to connect";
      _isConnected = false;
      notifyListeners();
    }
  }

  // ====================================
  // CALLBACKS
  // ====================================
  void _onConnected() {
    _connectionState = "Connected";
    _isConnected = true;

    // Request current device status after connection
    _requestDeviceStatus();

    notifyListeners();
  }

  void _requestDeviceStatus() {
    // In a real implementation, you might send a request to get current device status
    // For now, we'll just log that we're requesting status
    debugPrint("Requesting current device status...");
  }

  void _onDisconnected() {
    _connectionState = "Disconnected";
    _isConnected = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    debugPrint("Subscribed: $topic");
  }

  void _onAutoReconnected() {
    debugPrint("MQTT Client has auto-reconnected");
    _connectionState = "Reconnected";
    _isConnected = true;

    // Resubscribe to topics after reconnection
    _resubscribeTopics();

    notifyListeners();
  }

  void _resubscribeTopics() {
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      try {
        _client!.subscribe(suhuTopic, MqttQos.atMostOnce);
        _client!.subscribe(kelembapanTopic, MqttQos.atMostOnce);
        _client!.subscribe(lumenTopic, MqttQos.atMostOnce);
        _client!.subscribe(statusControlTopic, MqttQos.atMostOnce);
        _client!.subscribe(ledControlTopic, MqttQos.atMostOnce);

        debugPrint("Successfully resubscribed to all topics after reconnection");
      } catch (e) {
        debugPrint("Resubscription error: $e");
      }
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> list) {
    final msg = list[0];
    final topic = msg.topic;
    final payload = (msg.payload as MqttPublishMessage)
        .payload
        .message;

    final messageString = String.fromCharCodes(payload);

    // Periksa apakah ini pesan status LED
    if (topic == ledControlTopic) {
      bool newLedState = messageString == "1";
      updateLedState(newLedState);
    }

    // Simpan database
    if (_databaseProvider != null) {
      final ds = DataService(_databaseProvider!);
      ds.parseAndStoreMessage(topic, messageString);
    }

    // Callback ke UI
    onMessageReceived?.call(topic, messageString);
  }

  // ====================================
  // CAN PUBLISH - untuk kontrol akses
  // ====================================
  bool canPublish() {
    return _role == MqttUserRole.student;
  }

  // ====================================
  // PUBLISH (untuk LED START/STOP)
  // ====================================
  void publish(String topic, String payload) {
    if (!canPublish()) {
      debugPrint("Admin tidak boleh publish");
      return;
    }

    if (!isConnected) {
      debugPrint("Cannot publish: not connected to MQTT broker");
      return;
    }

    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

      debugPrint("Published to $topic: $payload");

      if (_databaseProvider != null) {
        final ds = DataService(_databaseProvider!);
        ds.storeCommand(topic, payload, "sent");
      }
    } catch (e) {
      debugPrint("Failed to publish to $topic: $e");
    }
  }

  // ====================================
  // CONTROL: LED ESP32
  // ====================================
  bool _ledState = false;
  bool get ledState => _ledState;

  void toggleLed() {
    final nextState = _ledState ? "0" : "1";

    publish(ledControlTopic, nextState);

    // Update state secara lokal sementara
    _ledState = !_ledState;
    notifyListeners();
  }

  // Metode untuk memperbarui state LED dari pesan MQTT
  void updateLedState(bool newState) {
    if (_ledState != newState) {
      _ledState = newState;
      notifyListeners();
    }
  }

  // START / STOP ESP32
  bool _deviceRunning = false;
  bool get deviceRunning => _deviceRunning;

  void startDevice() {
    publish(statusControlTopic, "START");
    _deviceRunning = true;
    notifyListeners();
  }

  void stopDevice() {
    publish(statusControlTopic, "STOP");
    _deviceRunning = false;
    notifyListeners();
  }

  // ====================================
  // DISCONNECT
  // ====================================
  void disconnect() {
    try {
      _client?.disconnect();
      _connectionState = "Disconnected";
      _isConnected = false;
      notifyListeners();
      debugPrint("MQTT Client disconnected");
    } catch (e) {
      debugPrint("Error during disconnection: $e");
    }
  }
}

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
  String broker = "10.46.113.50";
  int port = 1883;
  String username = "uas25_wika";   // MATCH ESP32
  String password = "uas25_wika";   // MATCH ESP32

  String get _defaultClientId => "flutter-client-33424225-${DateTime.now().millisecondsSinceEpoch}";
  String _clientId = "";

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
    _client = MqttServerClient(broker, _clientId);
    _client!.port = port;

    if (kIsWeb) {
      _client!.useWebSocket = true;
      _client!.secure = false;
    }

    _client!
      ..keepAlivePeriod = 60
      ..logging(on: false)
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed;

    final connMsg = MqttConnectMessage()
        .authenticateAs(username, password)
        .withClientIdentifier(_clientId)
        .startClean();

    _client!.connectionMessage = connMsg;

    try {
      _connectionState = "Connecting...";
      notifyListeners();

      await _client!.connect();
    } catch (e) {
      _connectionState = "Error: $e";
      _isConnected = false;
      notifyListeners();
      return;
    }

    if (_client!.connectionStatus!.state ==
        MqttConnectionState.connected) {
      // SUBSCRIBE semua topic
      _client!.subscribe(suhuTopic, MqttQos.atMostOnce);
      _client!.subscribe(kelembapanTopic, MqttQos.atMostOnce);
      _client!.subscribe(lumenTopic, MqttQos.atMostOnce);

      _client!.subscribe(statusControlTopic, MqttQos.atMostOnce);
      _client!.subscribe(ledControlTopic, MqttQos.atMostOnce);

      _client!.updates!.listen(_onMessage);
    }
  }

  // ====================================
  // CALLBACKS
  // ====================================
  void _onConnected() {
    _connectionState = "Connected";
    _isConnected = true;
    notifyListeners();
  }

  void _onDisconnected() {
    _connectionState = "Disconnected";
    _isConnected = false;
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    debugPrint("Subscribed: $topic");
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> list) {
    final msg = list[0];
    final topic = msg.topic;
    final payload = (msg.payload as MqttPublishMessage)
        .payload
        .message;

    final messageString = String.fromCharCodes(payload);

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

    if (!isConnected) return;

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _client!.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);

    if (_databaseProvider != null) {
      final ds = DataService(_databaseProvider!);
      ds.storeCommand(topic, payload, "sent");
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

    _ledState = !_ledState;
    notifyListeners();
  }

  // START / STOP ESP32
  void startDevice() => publish(statusControlTopic, "START");
  void stopDevice() => publish(statusControlTopic, "STOP");

  // ====================================
  // DISCONNECT
  // ====================================
  void disconnect() {
    _client?.disconnect();
  }
}

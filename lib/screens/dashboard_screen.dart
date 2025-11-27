import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/mqtt_provider.dart';
import '../providers/database_provider.dart';
import '../utils/recommendation_engine.dart';
import 'sensor_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _temperature = 0.0;
  double _humidity = 0.0;
  List<String> _recommendations = [];
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    // Set up MQTT message listener to update UI when new data arrives
    Provider.of<MqttProvider>(context, listen: false).onMessageReceived =
        (String topic, String message) {
      // Handle incoming sensor data
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);
      _handleIncomingData(topic, message, databaseProvider);
    };

    // Auto-connect to MQTT broker when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mqttProvider = Provider.of<MqttProvider>(context, listen: false);
      mqttProvider.connect();
    });
  }

  void _handleIncomingData(String topic, String message, DatabaseProvider databaseProvider) {
    if (topic.contains('/sensor/')) {
      // Parse the message as a number
      double? value = double.tryParse(message);
      if (value != null) {
        String sensorType = topic.contains('suhu') ? 'suhu' : 'humidity';

        // Update local state based on sensor type
        if (sensorType == 'suhu') {
          setState(() {
            _temperature = value;
            _hasData = true;
          });
        } else if (sensorType == 'humidity') {
          setState(() {
            _humidity = value;
            _hasData = true;
          });
        }

        // Generate recommendations based on current values
        if (_temperature != 0.0 && _humidity != 0.0) {
          setState(() {
            _recommendations = RecommendationEngine.getRecommendations(
              _temperature,
              _humidity
            );
          });
        }

        print('Received sensor data: $topic = $value');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('IoT Dashboard'),
          backgroundColor: Colors.blue[100],
          foregroundColor: Colors.blue[900],
          bottom: TabBar(
            labelColor: Colors.blue[900],
            unselectedLabelColor: Colors.blue[600],
            indicatorColor: Colors.blue[900],
            tabs: [
              Tab(text: 'Control'),
              Tab(text: 'History'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildControlTab(context),
            _buildHistoryTab(context),
            _buildSettingsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControlTab(BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section: Connection Status
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mqttProvider.isConnected ? Colors.blue[900] : Colors.grey,
                      ),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Connection Status: ${mqttProvider.connectionState}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NIM: ${mqttProvider.nim}',
                      style: TextStyle(
                        fontSize: 12, // Slightly smaller font
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Middle Section: Device Control Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Device Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LED Status',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        Switch(
                          value: mqttProvider.ledState,
                          onChanged: mqttProvider.isConnected
                              ? (value) {
                                  mqttProvider.toggleLed();
                                }
                              : null,
                          activeThumbColor: Colors.blue[300],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Bottom Section: Sensor Readings Cards
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensor Readings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Temperature
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.thermostat,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Temperature',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _hasData ? '${_temperature.toStringAsFixed(1)}°C' : '--°C',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Humidity
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  color: Colors.blue[300],
                                  size: 32,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Humidity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _hasData ? '${_humidity.toStringAsFixed(1)}%' : '--%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            // Footer: Disconnect Button
            ElevatedButton(
              onPressed: mqttProvider.isConnected ? () {
                mqttProvider.disconnect();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Disconnect',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Temperature Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temperature Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 180, // Reduced height to prevent overflow
                      child: FutureBuilder<List<SensorData>>(
                        future: databaseProvider.getSensorDataByType('suhu'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No temperature data available'));
                          } else {
                            List<SensorData> sensorData = snapshot.data!;
                            // Get only the last 20 records for the chart
                            if (sensorData.isNotEmpty && sensorData.length > 20) {
                              sensorData = sensorData.reversed.take(20).toList().reversed.toList();
                            }
                            return SensorChart(
                              sensorDataList: sensorData,
                              sensorType: 'suhu',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Humidity Chart
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Humidity Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 180, // Reduced height to prevent overflow
                      child: FutureBuilder<List<SensorData>>(
                        future: databaseProvider.getSensorDataByType('humidity'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(child: Text('No humidity data available'));
                          } else {
                            List<SensorData> sensorData = snapshot.data!;
                            // Get only the last 20 records for the chart
                            if (sensorData.isNotEmpty && sensorData.length > 20) {
                              sensorData = sensorData.reversed.take(20).toList().reversed.toList();
                            }
                            return SensorChart(
                              sensorDataList: sensorData,
                              sensorType: 'humidity',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Recommendations Section
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 16),
                    _recommendations.isNotEmpty
                      ? Column(
                          children: _recommendations.map((rec) => Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info, color: Colors.orange, size: 16),
                                SizedBox(width: 8),
                                Expanded(child: Text(rec)),
                              ],
                            ),
                          )).toList(),
                        )
                      : Text(
                          'No recommendations yet. Suggestions will appear when sensor values exceed thresholds.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context);
    final brokerController = TextEditingController(text: mqttProvider.broker);
    final portController = TextEditingController(text: mqttProvider.port.toString());
    final usernameController = TextEditingController(text: mqttProvider.username);
    final passwordController = TextEditingController(text: mqttProvider.password);
    final clientIdController = TextEditingController(text: mqttProvider.clientId);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MQTT Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 16),

            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Broker Host
                    TextFormField(
                      controller: brokerController,
                      decoration: InputDecoration(
                        labelText: 'Broker Host',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Port
                    TextFormField(
                      controller: portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.portrait),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),

                    // Username
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),

                    // Client ID (Read-only)
                    TextFormField(
                      controller: clientIdController,
                      decoration: InputDecoration(
                        labelText: 'Client ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag),
                      ),
                      readOnly: true,
                    ),
                    SizedBox(height: 24),

                    // Save & Connect Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Update the MQTT provider with new values
                          mqttProvider.broker = brokerController.text;
                          mqttProvider.port = int.tryParse(portController.text) ?? 1883;
                          mqttProvider.username = usernameController.text;
                          mqttProvider.password = passwordController.text;

                          // Disconnect first if currently connected
                          if (mqttProvider.isConnected) {
                            mqttProvider.disconnect();
                          }

                          // Connect with new settings
                          await mqttProvider.connect();

                          if (mounted) { // Check if widget is still mounted
                            if (mqttProvider.isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Connected successfully!'),
                                  backgroundColor: Colors.blue[300],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Connection failed: ${mqttProvider.connectionState}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[300],
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          'Save & Connect',
                          style: TextStyle(fontSize: 16, color: Colors.blue[900]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
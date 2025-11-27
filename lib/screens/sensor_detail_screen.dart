import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/database_provider.dart';
import 'sensor_chart.dart';

class SensorDetailScreen extends StatefulWidget {
  final String sensorType; // 'suhu' or 'humidity'

  const SensorDetailScreen({Key? key, required this.sensorType}) : super(key: key);

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {

  @override
  Widget build(BuildContext context) {
    String title = widget.sensorType == 'suhu' ? 'Temperature' : 'Humidity';
    IconData icon = widget.sensorType == 'suhu' ? Icons.thermostat : Icons.water_drop;
    Color color = widget.sensorType == 'suhu' ? Colors.red : Colors.blue[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('$title History'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Consumer<DatabaseProvider>(
          builder: (context, databaseProvider, child) {
            return FutureBuilder<List<SensorData>>(
              future: databaseProvider.getSensorDataByType(widget.sensorType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No data available for ${title.toLowerCase()}'));
                } else {
                  List<SensorData> sensorData = snapshot.data!;

                  // Get the latest value
                  double latestValue = sensorData.isNotEmpty ? sensorData.first.value : 0.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '${latestValue.toStringAsFixed(1)} ${widget.sensorType == 'suhu' ? "°C" : "%"}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Chart
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SensorChart(
                            sensorDataList: sensorData,
                            sensorType: widget.sensorType,
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Raw data list
                      Text(
                        'Recent Readings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: sensorData.length,
                          itemBuilder: (context, index) {
                            SensorData data = sensorData[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${data.timestamp.hour.toString().padLeft(2, '0')}:${data.timestamp.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          '${data.value.toStringAsFixed(1)} ${widget.sensorType == 'suhu' ? "°C" : "%"}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      widget.sensorType == 'suhu'
                                          ? Icons.thermostat
                                          : Icons.water_drop,
                                      color: color,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
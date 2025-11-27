import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mqtt_provider.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({Key? key}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreenState();
}

class _DeviceControlScreenState extends State<DeviceControlScreen> {
  final _topicController = TextEditingController();
  final _payloadController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final mqttProvider = Provider.of<MqttProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Device Control'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status indicator
            Container(
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: mqttProvider.isConnected ? Colors.blue[100]! : Colors.red[100]!,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mqttProvider.isConnected ? Colors.blue[600]! : Colors.red,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mqttProvider.isConnected ? Colors.blue[600] : Colors.red,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    mqttProvider.connectionState,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: mqttProvider.isConnected ? Colors.blue[800] : Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick LED control
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LED Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: mqttProvider.isConnected ? () {
                            mqttProvider.publish('polines/${mqttProvider.nim}/data/led', '1');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LED ON command sent')),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[300],
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            'Turn ON',
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: mqttProvider.isConnected ? () {
                            mqttProvider.publish('polines/${mqttProvider.nim}/data/led', '0');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('LED OFF command sent')),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text(
                            'Turn OFF',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Current LED State: ${mqttProvider.ledState ? "ON" : "OFF"}',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Manual publish section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Publish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _topicController,
                      decoration: InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., polines/33424225/test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _payloadController,
                      decoration: InputDecoration(
                        labelText: 'Payload',
                        hintText: 'e.g., 1 or Hello',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: mqttProvider.isConnected ? () {
                        if (_topicController.text.isNotEmpty && 
                            _payloadController.text.isNotEmpty) {
                          mqttProvider.publish(
                            _topicController.text, 
                            _payloadController.text
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Published to ${_topicController.text}: ${_payloadController.text}'),
                            ),
                          );
                          _payloadController.clear();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please fill in both topic and payload'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[300],
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        'Publish',
                        style: TextStyle(color: Colors.blue[900], fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Common topics
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Topics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    ListTile(
                      title: Text('polines/${mqttProvider.nim}/data/led'),
                      subtitle: Text('Control LED (payload: 1 or 0)'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'polines/${mqttProvider.nim}/data/led';
                      },
                    ),
                    ListTile(
                      title: Text('polines/${mqttProvider.nim}/data/sensor/suhu'),
                      subtitle: Text('Temperature data (payload: numeric value)'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'polines/${mqttProvider.nim}/data/sensor/suhu';
                      },
                    ),
                    ListTile(
                      title: Text('polines/${mqttProvider.nim}/data/sensor/humidity'),
                      subtitle: Text('Humidity data (payload: numeric value)'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'polines/${mqttProvider.nim}/data/sensor/humidity';
                      },
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
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
        title: const Text('Device Control'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status indicator
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 20),
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
                  const SizedBox(width: 8),
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LED Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected ? () {
                                mqttProvider.toggleLed();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('LED command sent')),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[300],
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: mqttProvider.ledState ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Toggle LED',
                                    style: TextStyle(color: Colors.blue[900]),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected ? () {
                                mqttProvider.startDevice();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('START command sent')),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'START Device',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: mqttProvider.isConnected ? () {
                                mqttProvider.stopDevice();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('STOP command sent')),
                                );
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'STOP Device',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // LED Status
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: mqttProvider.ledState ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'LED: ${mqttProvider.ledState ? "ON" : "OFF"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Device Status
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: mqttProvider.deviceRunning ? Colors.green[50] : Colors.grey[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: mqttProvider.deviceRunning ? Colors.green[200]! : Colors.grey[200]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: mqttProvider.deviceRunning ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    mqttProvider.deviceRunning ? 'RUNNING' : 'STOPPED',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mqttProvider.deviceRunning ? Colors.green[800] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Manual publish section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Publish',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _topicController,
                      decoration: const InputDecoration(
                        labelText: 'Topic',
                        hintText: 'e.g., polines/33424225/test',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _payloadController,
                      decoration: const InputDecoration(
                        labelText: 'Payload',
                        hintText: 'e.g., 1 or Hello',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                            const SnackBar(
                              content: Text('Please fill in both topic and payload'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[300],
                        padding: const EdgeInsets.symmetric(vertical: 15),
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
            
            const SizedBox(height: 20),
            
            // Common topics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Common Topics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('UAS25-IOT/${mqttProvider.nim}/LED'),
                      subtitle: const Text('Control LED (payload: 1 or 0)'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'UAS25-IOT/${mqttProvider.nim}/LED';
                      },
                    ),
                    ListTile(
                      title: Text('UAS25-IOT/${mqttProvider.nim}/SUHU'),
                      subtitle: const Text('Temperature data (payload: numeric value)'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'UAS25-IOT/${mqttProvider.nim}/SUHU';
                      },
                    ),
                    ListTile(
                      title: Text('UAS25-IOT/${mqttProvider.nim}/KELEMBAPAN'),
                      subtitle: const Text('Humidity data (payload: numeric value)'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'UAS25-IOT/${mqttProvider.nim}/KELEMBAPAN';
                      },
                    ),
                    ListTile(
                      title: Text('UAS25-IOT/${mqttProvider.nim}/LUMEN'),
                      subtitle: const Text('Lumen data (payload: numeric value)'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'UAS25-IOT/${mqttProvider.nim}/LUMEN';
                      },
                    ),
                    ListTile(
                      title: Text('UAS25-IOT/Status'),
                      subtitle: const Text('Control START/STOP (payload: START or STOP)'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _topicController.text = 'UAS25-IOT/Status';
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
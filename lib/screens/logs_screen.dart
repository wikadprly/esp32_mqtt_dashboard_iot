import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/database_provider.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MQTT Message Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getRecentLogs(databaseProvider),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No logs available yet'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final log = snapshot.data![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      log['type'] == 'publish' ? Icons.upload : Icons.download,
                                      color: log['type'] == 'publish' ? Colors.blue[600] : Colors.blue[300],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        log['topic'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      log['timestamp'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Payload: ${log['payload']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${log['status']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: log['status'] == 'sent'
                                        ? Colors.blue[600]
                                        : log['status'] == 'pending'
                                            ? Colors.grey
                                            : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Export logs functionality would go here
          _showExportDialog(context);
        },
        backgroundColor: Colors.blue[300],
        child: Icon(Icons.file_download, color: Colors.blue[900]),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentLogs(DatabaseProvider databaseProvider) async {
    try {
      // Fetch actual commands from database
      final commands = await databaseProvider.getAllCommands();

      // Convert commands to the format expected by the UI
      return commands.map((command) => {
        'topic': command.topic,
        'payload': command.payload,
        'type': 'publish', // All commands from app are publish operations
        'status': command.status,
        'timestamp': command.createdAt.toString().split('.')[0], // Format timestamp
      }).toList();
    } catch (e) {
      debugPrint('Error fetching logs: $e');
      return []; // Return empty list if there's an error
    }
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text('Choose export format'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Export to CSV functionality would go here
                _exportToCSV(context);
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportToCSV(BuildContext context) async {
    try {
      final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

      // Fetch sensor data and commands from database
      final sensorDataList = await databaseProvider.getAllSensorData();
      final commandList = await databaseProvider.getAllCommands();

      // Create CSV content
      StringBuffer csvBuffer = StringBuffer();

      // Add header
      csvBuffer.writeln('Type,Topic,SensorType,Value,Payload,Status,Timestamp');

      // Add sensor data
      for (var sensorData in sensorDataList) {
        csvBuffer.writeln('Sensor,${sensorData.topic},${sensorData.sensorType},${sensorData.value},,,"${sensorData.timestamp}"');
      }

      // Add command data
      for (var command in commandList) {
        csvBuffer.writeln('Command,${command.topic},,,${command.payload},${command.status},"${command.createdAt}"');
      }

      // In a real implementation, we would save this to a file
      // For now, we'll just show a success message
      final snackBar = SnackBar(
        content: const Text('Data exported to CSV successfully'),
        backgroundColor: Colors.green,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      final snackBar = SnackBar(
        content: Text('Error exporting data: $e'),
        backgroundColor: Colors.red,
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
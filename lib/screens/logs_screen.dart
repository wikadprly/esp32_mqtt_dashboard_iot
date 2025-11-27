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
        title: Text('Logs'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MQTT Message Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getRecentLogs(databaseProvider),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No logs available yet'));
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final log = snapshot.data![index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      log['type'] == 'publish' ? Icons.upload : Icons.download,
                                      color: log['type'] == 'publish' ? Colors.blue[600] : Colors.blue[300],
                                    ),
                                    SizedBox(width: 8),
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
                                SizedBox(height: 4),
                                Text(
                                  'Payload: ${log['payload']}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 4),
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
    // This would normally fetch from the database
    // For now, we'll return mock data
    return [
      {
        'topic': 'polines/33424225/data/led',
        'payload': '1',
        'type': 'publish',
        'status': 'sent',
        'timestamp': '2023-05-15 10:30:45',
      },
      {
        'topic': 'polines/33424225/data/sensor/suhu',
        'payload': '28.5',
        'type': 'subscribe',
        'status': 'received',
        'timestamp': '2023-05-15 10:30:40',
      },
      {
        'topic': 'polines/33424225/data/sensor/humidity',
        'payload': '65',
        'type': 'subscribe',
        'status': 'received',
        'timestamp': '2023-05-15 10:30:35',
      },
      {
        'topic': 'polines/33424225/data/led',
        'payload': '0',
        'type': 'publish',
        'status': 'sent',
        'timestamp': '2023-05-15 10:30:30',
      },
    ];
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Data'),
          content: Text('Choose export format'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Export to CSV functionality would go here
                _exportToCSV(context);
              },
              child: Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportToCSV(BuildContext context) async {
    // Placeholder for CSV export functionality
    print('Exporting data to CSV...');

    // In a real implementation, we would fetch data from database
    // and save it as a CSV file
    // For now, just show a success message
    final snackBar = SnackBar(
      content: Text('CSV export functionality would be implemented here'),
      backgroundColor: Colors.blue[300],
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
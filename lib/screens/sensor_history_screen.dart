import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../providers/database_provider.dart';

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({Key? key}) : super(key: key);

  @override
  _SensorHistoryScreenState createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  // Filter states
  String _selectedSensorType = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Loading state
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor History'),
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sensor type filter
                    Row(
                      children: [
                        Text(
                          'Sensor Type: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSensorType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All Sensors'),
                              ),
                              const DropdownMenuItem(
                                value: 'suhu',
                                child: Text('Temperature'),
                              ),
                              const DropdownMenuItem(
                                value: 'humidity',
                                child: Text('Humidity'),
                              ),
                              const DropdownMenuItem(
                                value: 'ldr',
                                child: Text('Light (LDR)'),
                              ),
                              const DropdownMenuItem(
                                value: 'lumen',
                                child: Text('Light (Lumen)'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSensorType = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Date range filter
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectStartDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _startDate != null 
                                ? 'From: ${_formatDate(_startDate!)}' 
                                : 'Select Start Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[200],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectEndDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              _endDate != null 
                                ? 'To: ${_formatDate(_endDate!)}' 
                                : 'Select End Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[200],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Clear filters button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // History list
            Expanded(
              child: _buildHistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return Consumer<DatabaseProvider>(
      builder: (context, databaseProvider, child) {
        return FutureBuilder<List<SensorData>>(
          future: _getFilteredSensorData(databaseProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No sensor data available'),
              );
            }
            
            final sensorDataList = snapshot.data!;
            
            return ListView.builder(
              itemCount: sensorDataList.length,
              itemBuilder: (context, index) {
                final data = sensorDataList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sensor type and value
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getSensorTypeName(data.sensorType),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getSensorColor(data.sensorType),
                                ),
                              ),
                            ),
                            Text(
                              '${data.value.toStringAsFixed(2)}${_getUnitSymbol(data.sensorType)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Topic
                        Text(
                          'Topic: ${data.topic}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        // Timestamp
                        Text(
                          'Time: ${_formatDateTime(data.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<SensorData>> _getFilteredSensorData(DatabaseProvider databaseProvider) async {
    List<SensorData> allData = await databaseProvider.getAllSensorData();
    
    // Apply sensor type filter
    if (_selectedSensorType != 'all') {
      allData = allData.where((data) => data.sensorType == _selectedSensorType).toList();
    }
    
    // Apply date range filter
    if (_startDate != null) {
      allData = allData.where((data) => data.timestamp.isAfter(_startDate!)).toList();
    }

    if (_endDate != null) {
      allData = allData.where((data) => data.timestamp.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }

    return allData;
  }

  String _getSensorTypeName(String sensorType) {
    switch (sensorType) {
      case 'suhu':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'ldr':
        return 'Light Intensity (LDR)';
      case 'lumen':
        return 'Light Intensity (Lumen)';
      default:
        return sensorType;
    }
  }

  Color _getSensorColor(String sensorType) {
    switch (sensorType) {
      case 'suhu':
        return Colors.red[700]!;
      case 'humidity':
        return Colors.blue[700]!;
      case 'ldr':
        return Colors.orange[700]!;
      case 'lumen':
        return Colors.yellow[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getUnitSymbol(String sensorType) {
    switch (sensorType) {
      case 'suhu':
        return '°C';
      case 'humidity':
        return '%';
      case 'ldr':
      case 'lumen':
        return ' lux';
      default:
        return '';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedSensorType = 'all';
      _startDate = null;
      _endDate = null;
    });
  }
}
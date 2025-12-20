import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';

class SensorChart extends StatelessWidget {
  final List<SensorData> sensorDataList;
  final String sensorType; // 'suhu', 'humidity', or 'lumen'

  const SensorChart({Key? key, required this.sensorDataList, required this.sensorType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String title;
    Color color;
    Color lineColor;

    if (sensorType == 'suhu') {
      title = 'Temperature (°C)';
      color = Colors.red;
      lineColor = Colors.red;
    } else if (sensorType == 'humidity') {
      title = 'Humidity (%)';
      color = Colors.blue;
      lineColor = Colors.blue;
    } else if (sensorType == 'lumen') {
      title = 'Lumen (Lux)';
      color = Colors.yellow[700]!;
      lineColor = Colors.yellow[700]!;
    } else {
      title = 'Sensor Data';
      color = Colors.grey;
      lineColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Container(
          height: 200,
          padding: const EdgeInsets.all(8.0),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 1,
                verticalInterval: 1,
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, titleMeta) {
                      if (sensorDataList.isEmpty) return const Text('');
                      int index = value.toInt();
                      if (index >= 0 && index < sensorDataList.length) {
                        DateTime time = sensorDataList[index].timestamp;
                        return Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 25,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, titleMeta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                    reservedSize: 25,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d)),
              ),
              minX: 0,
              maxX: sensorDataList.isNotEmpty ? sensorDataList.length - 1 : 0,
              minY: sensorDataList.isNotEmpty
                  ? sensorDataList.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 5
                  : 0,
              maxY: sensorDataList.isNotEmpty
                  ? sensorDataList.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 5
                  : 10,
              lineBarsData: [
                LineChartBarData(
                  spots: sensorDataList.asMap().entries.map((entry) {
                    int index = entry.key;
                    SensorData data = entry.value;
                    return FlSpot(index.toDouble(), data.value);
                  }).toList(),
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(
                    show: true,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
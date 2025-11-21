import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/mqtt_provider.dart';
import 'providers/database_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_control_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/sensor_detail_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
        ChangeNotifierProxyProvider<DatabaseProvider, MqttProvider>(
          create: (_) => MqttProvider(),
          update: (context, databaseProvider, mqttProvider) {
            mqttProvider?.setDatabaseProvider(databaseProvider);
            return mqttProvider ?? MqttProvider()..setDatabaseProvider(databaseProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: 'MQTT IoT App',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: DashboardScreen(),
        routes: {
          '/device_control': (context) => DeviceControlScreen(),
          '/logs': (context) => LogsScreen(),
        },
      ),
    );
  }
}
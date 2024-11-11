import 'package:flutter/material.dart';
import 'screens/weather_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimaQuick',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: WeatherScreen(),
    );
  }
}

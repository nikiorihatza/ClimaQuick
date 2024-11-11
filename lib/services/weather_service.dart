// weather_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  static const String apiKey = '3fead1991ad6d685e92fe903794b2436';

  // Fetch weather by city name
  static Future<Map<String, String>?> fetchWeather(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'temperature': data['main']['temp'].toString(),
        'description': data['weather'][0]['description'],
        'city': data['name'],
      };
    } else {
      return null;
    }
  }

  // Fetch weather by coordinates (latitude and longitude)
  static Future<Map<String, String>?> fetchWeatherByCoordinates(
      double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'temperature': data['main']['temp'].toString(),
        'description': data['weather'][0]['description'],
        'city': data['name'],
      };
    } else {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> fetchDayForecast(double lat, double lon) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<Map<String, dynamic>> forecastList = [];
      for (var forecast in data['list']) {
        var forecastData = {
          'date': forecast['dt_txt'],
          'temperature': forecast['main']['temp'],
          'description': forecast['weather'][0]['description'],
          'icon': forecast['weather'][0]['icon'],
        };
        forecastList.add(forecastData);
      }
      return forecastList; // Return the list of forecast data
    } else {
      return null;
    }
  }

  static Future<Map<String, double>?> getCoordinatesFromCity(String city) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'latitude': data['coord']['lat'],
        'longitude': data['coord']['lon'],
      };
    } else {
      return null;
    }
  }
}

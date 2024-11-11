import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sprintf/sprintf.dart';
import '../services/weather_service.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _temperature = '';
  String _description = '';
  String _city = 'Loading...';
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _forecast = [];
  int _selectedDay = 0; // 0 = today, 1 = tomorrow, etc.

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _getCurrentLocationWeather();
  }

  Future<void> _getCurrentLocationWeather() async {
    const double defaultLat = 40.7128; // New York City latitude
    const double defaultLon = -74.0060; // New York City longitude

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _fetchWeatherByCoordinates(position.latitude, position.longitude);
      _fetchDayForecast(position.latitude, position.longitude);
    } catch (e) {
      _fetchWeatherByCoordinates(defaultLat, defaultLon);
      _fetchDayForecast(defaultLat, defaultLon);
    }
  }

  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    final data = await WeatherService.fetchWeatherByCoordinates(lat, lon);
    if (data != null) {
      setState(() {
        _temperature = roundString(data['temperature']!);
        _description = data['description']!;
        _city = data['city']!;
        _isLoading = false;
        _hasError = false;
      });
      _animationController.forward();
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDayForecast(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=3fead1991ad6d685e92fe903794b2436&units=metric',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _forecast = data['list'].map<Map<String, dynamic>>((forecast) {
          return {
            'date': forecast['dt_txt'],
            'temperature': forecast['main']['temp'],
            'description': forecast['weather'][0]['description'],
            'icon': forecast['weather'][0]['icon'],
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _forecast = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather(String city) async {
    final coords = await WeatherService.getCoordinatesFromCity(city);
    if (coords != null) {
      final lat = coords['latitude']!;
      final lon = coords['longitude']!;
      _fetchWeatherByCoordinates(lat, lon);
      _fetchDayForecast(lat, lon);
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  String getDateInDays(int days) {
    DateTime today = DateTime.now();
    DateTime resultDay = today.add(Duration(days: days));

    return getOnlyDate(resultDay);
  }

  String getOnlyDate(DateTime date) {
    int day = date.day;
    int month = date.month;
    int year = date.year;

    return "$day.$month.$year";
  }

  String getDateAndTime(DateTime dateTime) {
    String date = getOnlyDate(dateTime);

    int hour = dateTime.hour;
    int minute = dateTime.minute;

    String time = sprintf("%02i:%02i",[hour,minute]);

    return "$date   $time";
  }

  String roundString(String doubleStr) {
    double doubleRound = double.parse(doubleStr);
    return doubleRound.ceil().toString();
  }

  String getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return 'assets/sunny.svg';
      case 'few clouds':
        return 'assets/few_clouds.svg';
      case 'scattered clouds':
      case 'broken clouds':
      case 'overcast clouds':
        return 'assets/cloudy.svg';
      case 'shower rain':
        return 'assets/shower_rain.svg';
      case 'rain':
        return 'assets/rainy.svg';
      case 'thunderstorm':
        return 'assets/thunderstorm.svg';
      case 'snow':
        return 'assets/snowing.svg';
      case 'mist':
      case 'fog':
        return 'assets/fog.svg';
      case 'smoke':
        return 'assets/smoke.svg';
      case 'haze':
        return 'assets/haze.svg';
      case 'dust':
        return 'assets/dust.svg';
      case 'sand':
      case 'ash':
        return 'assets/default.svg';
      case 'squall':
        return 'assets/squall.svg';
      case 'tornado':
        return 'assets/tornado.svg';
      default:
        return 'assets/default.svg';
    }
  }

  List<Map<String, dynamic>> getForecastForSelectedDay() {
    // Group the forecast by day
    final today = DateTime.now();
    final forecastForSelectedDay = <Map<String, dynamic>>[];
    for (var forecast in _forecast) {
      final forecastDate = DateTime.parse(forecast['date']);
      if (_selectedDay == 0 && forecastDate.day == today.day) {
        forecastForSelectedDay.add(forecast); // Today
      } else if (_selectedDay == 1 && forecastDate.day == today.day + 1) {
        forecastForSelectedDay.add(forecast); // Tomorrow
      } else if (_selectedDay == 2 && forecastDate.day == today.day + 2) {
        forecastForSelectedDay.add(forecast); // Day +1
      } else if (_selectedDay == 3 && forecastDate.day == today.day + 3) {
        forecastForSelectedDay.add(forecast); // Day +2
      }
    }
    return forecastForSelectedDay;
  }

  Widget _buildDayButton(String label, int dayIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 4.0), // Add spacing between buttons
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedDay == dayIndex ? Colors.blue : Colors.grey[300],
          foregroundColor:
              _selectedDay == dayIndex ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          setState(() {
            _selectedDay = dayIndex;
          });
        },
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Enter city name',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.all(17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final city = _controller.text;
                          _fetchWeather(city);
                        },
                        child: Icon(Icons.search, size: 24),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_hasError)
                    Center(
                        child: Text('Error fetching data',
                            style: TextStyle(color: Colors.red)))
                  else
                    Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeInAnimation,
                          child: Column(
                            children: [
                              Text(
                                'Weather in $_city',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 25),
                              SvgPicture.asset(
                                "${getWeatherIcon(_description)}",
                                width: 100,
                                height: 100,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Temperature: $_temperature°C',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              Text(
                                'Description: $_description',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        Text(
                          '4-Day Forecast:',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                              ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 50, // Height constraint for the horizontal ListView
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildDayButton('TODAY', 0),
                              _buildDayButton('TOMORROW', 1),
                              _buildDayButton(getDateInDays(2), 2),
                              _buildDayButton(getDateInDays(3), 3),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 350
                          ),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              key: ValueKey<int>(_selectedDay),
                              itemCount: getForecastForSelectedDay().length,
                              itemBuilder: (context, index) {
                                final forecast =
                                    getForecastForSelectedDay()[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.grey.shade200, width: 1),
                                  ),
                                  elevation: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Image.network(
                                          'http://openweathermap.org/img/wn/${forecast['icon']}@2x.png',
                                          width: 50,
                                          height: 50,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              getDateAndTime(DateTime.parse(forecast['date'])),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${forecast['temperature'].ceil()}°C',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              forecast['description'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }
}

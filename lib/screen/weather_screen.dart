import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/model/secrets.dart';
import 'package:weather_app/widget/additional_info.dart';
import 'package:weather_app/widget/hourly_forecast_item.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getCurrentWeather();
  }

  Future<void> getCurrentWeather() async {
    String cityName = "London";

    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIKey&units=metric',
        ),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          weatherData = data;
          isLoading = false;
        });
      } else {
        debugPrint(
            "Failed to load weather data. Status code: ${res.statusCode}");
        debugPrint("Response: ${res.body}");
      }
    } on SocketException {
      debugPrint("No Internet connection. Please check your network.");
    } catch (e) {
      debugPrint("Error occurred: $e");
    }
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case "clear":
        return Icons.sunny;
      case "clouds":
        return Icons.cloud;
      case "rain":
        return Icons.grain;
      case "fog":
        return Icons.foggy;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${weatherData?['city']['name'] ?? 'Unknown City'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Information Card
            SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            "${weatherData?['list'][0]['main']['temp']}°C",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Icon(
                            getWeatherIcon(weatherData!['list'][0]
                            ['weather'][0]['main']
                                .toString()),
                            size: 64,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            weatherData!['list'][0]['weather'][0]
                            ['description']
                                .toString(),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Weather Forecast Header
            const Text(
              "Weather Forecast",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Weather Forecast ListView
            SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weatherData?['list'].length,
                itemBuilder: (context, index) {
                  final forecast = weatherData?['list'][index];
                  final time = DateTime.parse(forecast?['dt_txt'] ?? "N/A");
                  final condition = forecast?['weather'][0]['main'] ?? "N/A";
                  final temp = forecast?['main']['temp'] ?? "N/A";
                  return HourlyForecastItem(
                    time: DateFormat.jm().format(time),
                    icon: getWeatherIcon(condition.toString()),
                    temperature: "$temp°C",
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Additional Information Header
            const Text(
              "Additional Information",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Additional Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AdditionalInfo(
                  icon: Icons.water_drop,
                  label: "Humidity",
                  value:
                  "${weatherData?['list'][0]['main']['humidity'] ?? 'N/A'}%",
                ),
                AdditionalInfo(
                  icon: Icons.air,
                  label: "Wind Speed",
                  value: "${weatherData?['list'][0]['wind']['speed']} m/s",
                ),
                AdditionalInfo(
                  icon: Icons.beach_access,
                  label: "Pressure",
                  value:
                  "${weatherData?['list'][0]['main']['pressure']} hPa",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: avoid_unnecessary_containers, sized_box_for_whitespace

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main(List<String> args) => runApp(const WeatherApp());

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  int? temp;
  String location = 'Jakarta';
  String weather = 'clear';
  int woeid = 1047378;
  String abbr = 'c';

  String errorMessage = '';

  // Temp List
  var minTempForecast = List.filled(7, 0);
  var maxTempForecast = List.filled(7, 0);
  var abbrForecast = List.filled(7, '');

  String searchApiURL =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiURL = 'https://www.metaweather.com/api/location/';

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
  }

  Future<void> fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiURL + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
      });
    } catch (erroe) {
      errorMessage = 'City Not Found, Try Another';
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiURL + woeid.toString()));
    var result = json.decode(locationResult.body);
    var consolidatedWeather = result['consolidated_weather'];
    var data = consolidatedWeather[0];

    abbr = data['weather_state_abbr'];

    setState(() {
      temp = data['the-temp'].round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
    });
  }

  Future<void> fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiURL +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString()));
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTempForecast[i] = data['min_temp'].round();
        maxTempForecast[i] = data['max_temp'].round();
        abbrForecast[i] = data['weather_state_abbr'];
      });
    }
  }

  Future<void> onTextSubmitted(String input) async {
    await fetchLocation();
    await fetchSearch(input);
    await fetchLocationDay();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('images/$weather.png'), fit: BoxFit.cover),
        ),
        child: temp == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Center(
                          child: Image.network(
                            'https://www.metaweather.com/static/img/weather/png/' +
                                abbr +
                                '.png',
                            width: 100,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Text(
                          temp.toString() + '°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                          ),
                        ),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for(var i = 0; i < 7; i++)
                            forecastElement(i + 1, abbrForecast[i], maxTempForecast[i], minTempForecast[i]) 
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 240,
                          child: TextField(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                            decoration: const InputDecoration(
                                hintText: 'Select Another Location',
                                hintStyle: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                prefixIcon: Icon(Icons.search)),
                            onSubmitted: (String input) {
                              onTextSubmitted(input);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                          ),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: Platform.isAndroid ? 15 : 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

Widget forecastElement(daysFromNow, abbr, maxTemp, minTemp) {
  var now = DateTime.now();
  var oneDayAfter = now.add(Duration(days: daysFromNow));

  return Padding(
    padding: const EdgeInsets.only(
      left: 16,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(205, 212, 228, 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat.E().format(oneDayAfter),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            Text(
              DateFormat.MMMd().format(oneDayAfter),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Image.network(
                'https://www.metaweather.com/static/img/weather/png/' +
                    abbr +
                    '.png',
                width: 50,
              ),
            ),
            Text(
              'High ' + maxTemp.toString() + '°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            Text(
              'Low ' + minTemp.toString() + '°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

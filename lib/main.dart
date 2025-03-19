import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Temperatura y Control de LED RGB',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TemperatureScreen(),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  String temperature = "Cargando...";
  String humidity = "Cargando...";
  List<BarChartGroupData> temperatureData = [];
  List<BarChartGroupData> humidityData = [];
  Timer? _timer;

  Future<void> fetchData() async {
    final String username = "DanielCr24";
    final String key = "aio_iQuj072waO7acE9ymKFADOxRU4W0";

    final urlTemperature = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/temperature/data/last',
      {'X-AIO-Key': key},
    );

    final urlHumidity = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/humidity/data/last',
      {'X-AIO-Key': key},
    );

    try {
      final responseTemperature = await http.get(urlTemperature);
      final responseHumidity = await http.get(urlHumidity);

      if (responseTemperature.statusCode == 200 && responseHumidity.statusCode == 200) {
        final dataTemperature = json.decode(responseTemperature.body);
        final dataHumidity = json.decode(responseHumidity.body);

        if (dataTemperature != null && dataTemperature['value'] != null) {
          setState(() {
            temperature = "${dataTemperature['value']} °C"; // Agregar unidad de medida
            temperatureData.add(BarChartGroupData(
              x: DateTime.now().millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(dataTemperature['value']) ?? 0.0,
                  color: Colors.lightGreen,
                ),
              ],
            ));
            if (temperatureData.length > 10) {
              temperatureData.removeAt(0);
            }
          });
        }

        if (dataHumidity != null && dataHumidity['value'] != null) {
          setState(() {
            humidity = "${dataHumidity['value']} %"; // Agregar unidad de medida
            humidityData.add(BarChartGroupData(
              x: DateTime.now().millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(dataHumidity['value']) ?? 0.0,
                  color: Colors.blueAccent,
                ),
              ],
            ));
            if (humidityData.length > 10) {
              humidityData.removeAt(0);
            }
          });
        }
      } else {
        setState(() {
          temperature = "Error al cargar la temperatura. Código: ${responseTemperature.statusCode}";
          humidity = "Error al cargar la humedad. Código: ${responseHumidity.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Error de conexión al obtener la temperatura.";
        humidity = "Error de conexión al obtener la humedad.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperatura y Control de LED RGB'),
        backgroundColor: Colors.white70,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Fondo de clima
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/sunny_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Filtro para contraste
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          // Contenido
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    Card(
                      elevation: 5,
                      color: Colors.white.withOpacity(0.65),
                      child: ListTile(
                        leading: Icon(Icons.thermostat_outlined, color: Colors.green, size: 40),
                        title: Text(
                          'Temperatura actual:',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            temperature, // Ya tiene la unidad °C
                            style: TextStyle(fontSize: 32, color: Colors.green),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemperatureGraphScreen(
                                temperatureData: temperatureData,
                                humidityData: humidityData,
                                graphType: 'temperature',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Card(
                      elevation: 5,
                      color: Colors.white.withOpacity(0.65),
                      child: ListTile(
                        leading: Icon(Icons.water_drop_outlined, color: Colors.blueAccent, size: 40),
                        title: Text(
                          'Humedad actual:',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            humidity, // Ya tiene la unidad %
                            style: TextStyle(fontSize: 32, color: Colors.blueAccent),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemperatureGraphScreen(
                                temperatureData: temperatureData,
                                humidityData: humidityData,
                                graphType: 'humidity',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Colors.blueAccent,
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                      ),
                      onPressed: fetchData,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Actualizar datos',
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureGraphScreen extends StatelessWidget {
  final List<BarChartGroupData> temperatureData;
  final List<BarChartGroupData> humidityData;
  final String graphType;

  TemperatureGraphScreen({
    required this.temperatureData,
    required this.humidityData,
    required this.graphType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white70,
        elevation: 0,
        title: Text('Gráfico de ${graphType == 'temperature' ? 'Temperatura' : 'Humedad'}'),
      ),
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/sunny_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Filtro
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 80),
                Text(
                  'Gráfico de ${graphType == 'temperature' ? 'Temperatura' : 'Humedad'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                DateTime time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Text(
                                  "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: graphType == 'temperature' ? temperatureData : humidityData,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';  // Importar fl_chart

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
  String temperature = "Cargando..."; // Valor inicial de la temperatura
  String humidity = "Cargando..."; // Valor inicial de la humedad
  List<BarChartGroupData> temperatureData = [];  // Lista para los datos de la temperatura
  List<BarChartGroupData> humidityData = [];     // Lista para los datos de la humedad
  Timer? _timer; // Instancia de Timer

  // Función para obtener la temperatura y la humedad desde Adafruit IO
  Future<void> fetchData() async {
    final String username = "DanielCr24"; // Tu nombre de usuario
    final String key = "aio_iQuj072waO7acE9ymKFADOxRU4W0"; // Tu clave de Adafruit IO

    // URLs para obtener los datos del feed de temperatura y humedad
    final urlTemperature = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/temperature/data/last',
      {'X-AIO-Key': key}, // Encabezado con la clave de acceso
    );

    final urlHumidity = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/humidity/data/last',
      {'X-AIO-Key': key}, // Encabezado con la clave de acceso
    );

    print("Intentando obtener datos desde: $urlTemperature y $urlHumidity");

    try {
      final responseTemperature = await http.get(urlTemperature);
      final responseHumidity = await http.get(urlHumidity);

      if (responseTemperature.statusCode == 200 && responseHumidity.statusCode == 200) {
        final dataTemperature = json.decode(responseTemperature.body);
        final dataHumidity = json.decode(responseHumidity.body);

        if (dataTemperature != null && dataTemperature['value'] != null) {
          setState(() {
            temperature = dataTemperature['value']; // Extraer la temperatura
            // Agregar la nueva lectura de temperatura al gráfico como una barra
            temperatureData.add(BarChartGroupData(
              x: DateTime.now().millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(temperature) ?? 0.0,  // Convertir la temperatura a double
                  color: Colors.lightGreen,
                ),
              ],
            ));
            if (temperatureData.length > 10) {
              temperatureData.removeAt(0);  // Mantener solo los últimos 10 valores
            }
          });
        }

        if (dataHumidity != null && dataHumidity['value'] != null) {
          setState(() {
            humidity = dataHumidity['value']; // Extraer la humedad
            // Agregar la nueva lectura de humedad al gráfico como una barra
            humidityData.add(BarChartGroupData(
              x: DateTime.now().millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(humidity) ?? 0.0,  // Convertir la humedad a double
                  color: Colors.blueAccent,  // Diferente color para la humedad
                ),
              ],
            ));
            if (humidityData.length > 10) {
              humidityData.removeAt(0);  // Mantener solo los últimos 10 valores
            }
          });
        }
      } else {
        setState(() {
          temperature = "Error al cargar la temperatura. Código de estado: ${responseTemperature.statusCode}";
          humidity = "Error al cargar la humedad. Código de estado: ${responseHumidity.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        temperature = "Error de conexión al obtener la temperatura.";
        humidity = "Error de conexión al obtener la humedad.";
      });
      print("Error al obtener los datos: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Llamada a la función para obtener la temperatura y humedad cuando la pantalla se carga
    // Actualizar los datos cada 5 minutos usando Timer
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el Timer cuando la pantalla se destruya
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Temperatura y Control de LED RGB'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card para la temperatura
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.thermostat_outlined, color: Colors.lightGreen, size: 40),  // Icono de temperatura
                    title: Text(
                      'Temperatura actual:',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        temperature, // Mostrar la temperatura
                        style: TextStyle(fontSize: 32, color: Colors.lightGreen),
                      ),
                    ),
                    onTap: () {
                      // Acción al presionar la card de temperatura, navegar a la pantalla del gráfico
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemperatureGraphScreen(
                            temperatureData: temperatureData,
                            humidityData: humidityData,
                            graphType: 'temperature', // Pasar tipo de gráfico
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Card para la humedad
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.water_drop_outlined, color: Colors.blueAccent, size: 40),  // Icono de humedad
                    title: Text(
                      'Humedad actual:',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        humidity, // Mostrar la humedad
                        style: TextStyle(fontSize: 32, color: Colors.blueAccent),
                      ),
                    ),
                    onTap: () {
                      // Acción al presionar la card de humedad
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemperatureGraphScreen(
                            temperatureData: temperatureData,
                            humidityData: humidityData,
                            graphType: 'humidity', // Pasar tipo de gráfico
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Botón para actualizar la temperatura y humedad
                ElevatedButton(
                  onPressed: fetchData, // Actualizar los datos al presionar el botón
                  child: Text('Actualizar datos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TemperatureGraphScreen extends StatelessWidget {
  final List<BarChartGroupData> temperatureData;
  final List<BarChartGroupData> humidityData;
  final String graphType; // Para saber qué gráfico mostrar

  // Constructor para recibir los datos de temperatura y humedad
  TemperatureGraphScreen({
    required this.temperatureData,
    required this.humidityData,
    required this.graphType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico de ${graphType == 'temperature' ? 'Temperatura' : 'Humedad'}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Gráfico de ${graphType == 'temperature' ? 'Temperatura' : 'Humedad'}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Gráfico de barras para la temperatura
            Container(
              height: 300, // Definir altura para el gráfico
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          // Convertir el valor (tiempo en milisegundos) a hora
                          DateTime time = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          // Formato de hora: hora:minuto
                          return Text(
                            "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 30, // Esto es el espacio reservado para los títulos
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: graphType == 'temperature' ? temperatureData : humidityData, // Mostrar solo el gráfico correspondiente
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

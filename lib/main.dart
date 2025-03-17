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
  List<BarChartGroupData> temperatureData = [];  // Lista para los datos de la temperatura
  Timer? _timer; // Instancia de Timer

  // Función para obtener la temperatura desde Adafruit IO
  Future<void> fetchTemperature() async {
    final String username = "DanielCr24"; // Tu nombre de usuario
    final String key = "aio_iQuj072waO7acE9ymKFADOxRU4W0"; // Tu clave de Adafruit IO
    final String feedName = "temperature"; // El nombre de tu feed (asegúrate de que es correcto)

    // La URL para obtener los datos del feed
    final url = Uri.https(
      'io.adafruit.com',
      '/api/v2/$username/feeds/$feedName/data/last',
      {'X-AIO-Key': key}, // Encabezado con la clave de acceso
    );

    print("Intentando obtener temperatura desde: $url");

    try {
      final response = await http.get(url);

      print("Código de estado HTTP al obtener la temperatura: ${response.statusCode}");
      print("Respuesta: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Comprobar si la respuesta contiene datos válidos
        if (data != null && data['value'] != null) {
          setState(() {
            temperature = data['value']; // Extraer la temperatura directamente
            // Agregar la nueva lectura al gráfico como una barra
            temperatureData.add(BarChartGroupData(
              x: DateTime.now().millisecondsSinceEpoch,
              barRods: [
                BarChartRodData(
                  toY: double.tryParse(temperature) ?? 0.0,  // Convertir la temperatura a double
                  color: Colors.blue,
                ),
              ],
            ));
            if (temperatureData.length > 10) {
              temperatureData.removeAt(0);  // Mantener solo los últimos 10 valores
            }
          });
        } else {
          setState(() {
            temperature = "No se encontraron datos de temperatura.";
          });
        }
      } else {
        setState(() {
          temperature = "Error al cargar la temperatura. Código de estado: ${response.statusCode}";
        });
        print("Error al cargar la temperatura: ${response.body}");
      }
    } catch (e) {
      setState(() {
        temperature = "Error de conexión al obtener la temperatura.";
      });
      print("Error al obtener la temperatura: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTemperature(); // Llamada a la función para obtener la temperatura cuando la pantalla se carga
    // Actualizar la temperatura cada 5 minutos usando Timer
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      fetchTemperature();
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
                    title: Text(
                      'Temperatura actual:',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        temperature, // Mostrar la temperatura
                        style: TextStyle(fontSize: 32, color: Colors.blue),
                      ),
                    ),
                    onTap: () {
                      // Acción al presionar la card de temperatura, navegar a la pantalla del gráfico
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TemperatureGraphScreen(temperatureData: temperatureData),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),

                // Botón para actualizar la temperatura
                ElevatedButton(
                  onPressed: fetchTemperature, // Actualizar la temperatura al presionar el botón
                  child: Text('Actualizar Temperatura'),
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

  // Constructor para recibir los datos de temperatura
  TemperatureGraphScreen({required this.temperatureData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráfico de Temperatura'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Gráfico de Temperatura',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Gráfico de barras
            Container(
              height: 300, // Definir altura para el gráfico
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: temperatureData, // Mostrar los datos de temperatura
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

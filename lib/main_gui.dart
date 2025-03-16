import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // <- Agrega este package a tu pubspec.yaml
import 'mqtt_stream.dart';
import 'Adafruit_feed.dart';

class MqttGui extends StatefulWidget {
  @override
  _MqttGuiState createState() => _MqttGuiState();
}

class _MqttGuiState extends State<MqttGui> {
  AppMqttTransactions myMQTT = AppMqttTransactions();
  final topicController = TextEditingController();
  Color currentColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Native MQTT"),
        centerTitle: true,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: [
        _subsCriptionData(),
        SizedBox(height: 20.0,),
        _viewData(),
        SizedBox(height: 20.0,),
        _colorPickerWidget(),
      ],
    );
  }

  Widget _subsCriptionData() {
    return Container(
      margin: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 20.0),
      child: Column(
        children: [
          Row(
            children: [
              Text("Feed/Topic:",
                style: TextStyle(fontSize: 20, color: Colors.grey),),
              Flexible(child: TextField(
                controller: topicController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ))
            ],
          ),
          SizedBox(
            height: 20.0,
          ),
          ElevatedButton(
            onPressed: () {
              subscribe(topicController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: Text("Suscribir", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(
            height: 20.0,
          ),
          Text("Valor recibido del Feed (sensor, etc.)")
        ],
      ),
    );
  }

  Widget _viewData() {
    return StreamBuilder(
        stream: AdafruitFeed.sensorStream,
        builder: (context, snapshot) {
          String? reading = snapshot.data;
          if (reading == null) {
            reading = "No hay un valor definido";
          }
          return Text(reading);
        });
  }

  Widget _colorPickerWidget() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        children: [
          Text(
            "Selecciona un color para el LED",
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (Color color) {
              setState(() {
                currentColor = color;
              });
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.6,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              sendColorToMqtt();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentColor,
            ),
            child: Text("Enviar Color", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void sendColorToMqtt() {
    if (topicController.text.isEmpty) return;

    int r = currentColor.red;
    int g = currentColor.green;
    int b = currentColor.blue;

    String rgbString = "$r,$g,$b"; // Enviamos como "255,100,50"
    publish(topicController.text, rgbString);
  }

  void subscribe(String feed) {
    myMQTT.subscribe(feed);
  }

  void publish(String feed, String value) {
    myMQTT.publish(feed, value);
  }

}

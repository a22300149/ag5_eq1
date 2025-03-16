import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'mqtt_stream.dart';
import 'Adafruit_feed.dart';

class MqttGui extends StatefulWidget {
  @override
  _MqttGuiState createState() => _MqttGuiState();
}

class _MqttGuiState extends State<MqttGui> {
  AppMqttTransactions myMQTT = AppMqttTransactions();
  final topicController = TextEditingController();
  final valueController = TextEditingController();

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
        _publishData(),
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
                    border: OutlineInputBorder(

                    )
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
          Text("Valor recibido de el Feed (sensor, etc.)")
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
            reading = "Nohay un valor definido";
          }
          return Text(reading);
        });
  }

  Widget _publishData() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        children: [
          Row(
              children: [
                Text(
                  "Value:",
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
                Flexible(
                    child: TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Valor para publicar"
                      ),
                    ))
              ]
          ),
          SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () {
              publish(topicController.text, valueController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: Text("Enviar datos", style: TextStyle(color: Colors.white)),
          ),
          SizedBox(height: 20,),
        ],
      ),
    );
  }

  void subscribe(String feed) {
    myMQTT.subscribe(feed);
  }

  void publish(String feed, String value) {
    myMQTT.publish(feed, value);
  }

}

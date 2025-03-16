import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';

class AppMqttTransactions {
  late MqttClient client;
  String? previousTopic;
  bool bAlreadySubscribed = false;

  final StreamController<String> _mqttStreamController = StreamController<String>.broadcast();

  Stream<String> get mqttStream => _mqttStreamController.stream;

  AppMqttTransactions();

  Future<bool> subscribe(String topic) async {
    if (await _connectToClient()) {
      client.onDisconnected = _onDisconnected;
      client.onConnected = _onConnected;
      client.onSubscribed = _onSubscribed;
      await _subscribe(topic);
      return true;
    }
    return false;
  }

  Future<bool> _connectToClient() async {
    if (client.connectionStatus != null &&
        client.connectionStatus!.state == MqttConnectionState.connected) {
      return true;
    } else {
      await _login();
      return client.connectionStatus != null &&
          client.connectionStatus!.state == MqttConnectionState.connected;
    }
  }

  void _onSubscribed(String topic) {
    bAlreadySubscribed = true;
    previousTopic = topic;
  }

  void _onDisconnected() {
    client.disconnect();
  }

  void _onConnected() {}

  Future<Map<String, dynamic>> _getBrokerAndKey() async {
    String connect = await rootBundle.loadString('config/private.json');
    return json.decode(connect);
  }

  Future<void> _login() async {
    final connectJson = await _getBrokerAndKey();
    client = MqttClient(connectJson['broker'], '');
    client.logging(on: true);
    final connMess = MqttConnectMessage()
        .authenticateAs(connectJson['username'], connectJson['key'])
        .withClientIdentifier('myClientID')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception {
      client.disconnect();
    }
  }

  Future<void> _subscribe(String topic) async {
    if (bAlreadySubscribed && previousTopic != null) {
      client.unsubscribe(previousTopic!);
    }

    client.subscribe(topic, MqttQos.atMostOnce);

    // Aquí verificamos que updates no sea null antes de escuchar
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String pt =
      MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _mqttStreamController.add(pt);
    });
  }

  Future<void> publish(String topic, String value) async {
    if (await _connectToClient()) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(value);
      client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void dispose() {
    _mqttStreamController.close();
    client.disconnect();
  }
}

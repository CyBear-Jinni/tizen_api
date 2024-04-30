import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:tizen_api/src/api/key_codes.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'device.dart';

class TV {
  String id;
  String isSupport;
  String name;
  String remote;
  String type;
  String uri;
  String version;
  Device device;
  WebSocketChannel? _socket;

  TV({
    required this.id,
    required this.isSupport,
    required this.name,
    required this.remote,
    required this.type,
    required this.uri,
    required this.version,
    required this.device,
  });

  factory TV.fromJson(Map<String, dynamic> json) {
    return TV(
      id: json['id'],
      isSupport: json['isSupport'],
      name: json['name'],
      remote: json['remote'],
      type: json['type'],
      uri: json['uri'],
      version: json['version'],
      device: Device.fromJson(json['device']),
    );
  }

  static const Map<String, String> applications = {
    "youtube": "111299001912",
    "spotify": "3201606009684",
    "netflix": "11101200001",
    "amazon": "3201512006785",
    "disney": "3201807016598",
  };

  void forwardToApplication(String application) =>
      Dio().post("${uri}applications/${applications[application]!}");

  connectToSocket(String? token) {
    final name = base64Encode("widgy-smart-remote".codeUnits);
    String tvIP = device.ip;
    String tvName = name;
    print("connecting to $tvName ($tvIP)...");
    _socket = WebSocketChannel.connect(
      Uri(
        scheme: "wss",
        host: tvIP,
        port: 8002,
        path: "/api/v2/channels/samsung.remote.control",
        queryParameters: {
          "name": name,
          "token": token,
        },
      ),
    );
  }

  Stream? socketStream() => _socket?.stream;

  addToSocket(KeyCodes key) => _socket?.sink.add(jsonEncode(
        {
          "method": "ms.remote.control",
          "params": {
            "Cmd": "Click",
            "DataOfCmd": key.name,
            "Option": "false",
            "TypeOfRemote": "SendRemoteKey"
          }
        },
      ));
}

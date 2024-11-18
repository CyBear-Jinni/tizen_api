import 'dart:convert';
import 'dart:io';

import 'package:tizen_api/src/api/key_codes.dart';
import 'package:tizen_api/src/api/models/device.dart';
import 'package:tizen_api/src/tizen_helper_methods.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Tv {
  Tv({
    required this.id,
    required this.isSupport,
    required this.name,
    required this.remote,
    required this.type,
    required this.uri,
    required this.version,
    required this.device,
  });
  factory Tv.fromJson(Map<String, dynamic> json, String ip) {
    return Tv(
      id: json['id'] as String,
      isSupport: json['isSupport'] as String,
      name: json['name'] as String,
      remote: json['remote'] as String,
      type: json['type'] as String,
      uri: json['uri'] as String,
      version: json['version'] as String,
      device: Device.fromJson(json['device'] as Map<String, dynamic>, ip),
    );
  }

  String id;
  String isSupport;
  String name;
  String remote;
  String type;
  String uri;
  String version;
  Device device;
  WebSocketChannel? _socket;

  static const Map<String, String> applications = {
    'youtube': '111299001912',
    'spotify': '3201606009684',
    'netflix': '11101200001',
    'amazon': '3201512006785',
    'disney': '3201807016598',
  };

  void forwardToApplication(String application) => TizenHelperMethods.postFixed(
        '${uri}applications/${applications[application]!}',
      );

  void connectToSocket(String? token) {
    final String name = base64Encode('tizen_api'.codeUnits);
    final String tvIP = device.ip;
    final String tvName = name;
    TizenHelperMethods.log('connecting to $tvName ($tvIP)...');
    HttpOverrides.runZoned(
      () => _socket = WebSocketChannel.connect(
        Uri(
          scheme: 'wss',
          host: tvIP,
          port: 8002,
          path: '/api/v2/channels/samsung.remote.control',
          queryParameters: {
            'name': name,
            'token': token,
          },
        ),
      ),
      createHttpClient: (SecurityContext? context) => MyHttpOverrides()
          .createHttpClient(context)
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => host == device.ip,
    ); // Other HTTP requests outside this zone are unaffected
  }

  Stream? socketStream() => _socket?.stream;

  void addToSocket(KeyCodes key) => _socket?.sink.add(
        jsonEncode(
          {
            'method': 'ms.remote.control',
            'params': {
              'Cmd': 'Click',
              'DataOfCmd': key.command,
              'Option': 'false',
              'TypeOfRemote': 'SendRemoteKey',
            },
          },
        ),
      );
}

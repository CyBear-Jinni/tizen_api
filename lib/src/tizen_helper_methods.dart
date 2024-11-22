import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tizen_api/src/api/models/tv.dart';

class TizenHelperMethods {
  static Tv? selectedTv;

  static Future<Response> getFixed(String path) async {
    return HttpOverrides.runZoned(
      () => Dio().get(path),
      createHttpClient: (SecurityContext? context) =>
          MyHttpOverrides().createHttpClient(context)
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) =>
                    TizenHelperMethods.selectedTv?.device.ip != null &&
                    host == TizenHelperMethods.selectedTv?.device.ip,
    ); // Other HTTP requests outside this zone are unaffected
  }

  static Future postFixed(String path) async {
    return HttpOverrides.runZoned(
      () {
        Dio().post(path);
      },
      createHttpClient: (SecurityContext? context) =>
          MyHttpOverrides().createHttpClient(context)
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) =>
                    TizenHelperMethods.selectedTv?.device.ip != null &&
                    host == TizenHelperMethods.selectedTv?.device.ip,
    ); // Other HTTP requests outside this zone are unaffected
  }

  static void log(String message) {
    print('[Tizen API] $message');
  }

  static Stream<Tv> scanNetwork(String ip) async* {
    log('Scan started, it may take a while');
    log('IP: $ip');
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    const int port = 8002;

    for (var i = 0; i < 256; i++) {
      final String ip = '$subnet.$i';
      final Tv? tv = await TizenHelperMethods.checkSocket(ip, port);
      if (tv == null) {
        continue;
      }
      yield tv;
    }

    // Close the stream controller when all futures are completed
    log('Scan completed');
  }

  static Stream<String?> setupStream(String? token) async* {
    if (TizenHelperMethods.selectedTv == null) {
      return;
    }
    TizenHelperMethods.selectedTv!.connectToSocket(token);
    final Stream? tvStream = TizenHelperMethods.selectedTv!.socketStream();
    if (tvStream == null) {
      return;
    }
    await for (final dynamic stream in tvStream) {
      log('Received a message: $stream');

      try {
        final Map<String, dynamic> json =
            jsonDecode(stream as String) as Map<String, dynamic>;

        final Map<String, dynamic> data = json['data'] as Map<String, dynamic>;
        final dynamic dynamicToken = data['token'];
        final dynamic dynamicId = data['id'];
        if (dynamicToken is String) {
          final String token = dynamicToken;
          log('Received a new token: $token');
          yield token;
        } else if (dynamicId is String) {
          final String id = dynamicId;
          log('Received a new id: $id');
          yield id;
        }
      } catch (e) {
        log('Error parsing message: $e');
      }
    }
  }

  static Future<Tv?> checkSocket(String host, int port) async {
    try {
      final Socket socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 50),
      );
      final String ip = socket.address.address;
      socket.destroy();

      log('Checking TV at $ip');
      final String path = 'http://$ip:8001/api/v2/';
      final Response response = await TizenHelperMethods.getFixed(path);
      log('Found TV at $ip');
      return Tv.fromJson(response.data as Map<String, dynamic>, ip);
    } catch (e) {
      log('Error: $e');
    }

    return null;
  }
}

class MyHttpOverrides extends HttpOverrides {}

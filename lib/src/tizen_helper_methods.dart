import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:network_info_plus/network_info_plus.dart';
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

  static Future<void> scanNetwork(
    Function(Future<Socket>) socketTaskFunction,
  ) async {
    log('Scan started, it may take a while');
    final String? ip = await NetworkInfo().getWifiIP();
    log('IP: $ip');
    final String subnet = ip!.substring(0, ip.lastIndexOf('.'));
    const int port = 8002;
    for (var i = 0; i < 256; i++) {
      final String ip = '$subnet.$i';
      final Future<Socket> socketTask =
          Socket.connect(ip, port, timeout: const Duration(milliseconds: 50));
      socketTaskFunction.call(socketTask);
    }
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
        final Map<String, Map<String, String?>> json =
            jsonDecode(stream as String) as Map<String, Map<String, String?>>;

        final String? token = json['data']?['token'];
        if (token != null) {
          log('Received a new token: $token');
          yield token;
        }
      } catch (e) {
        log('Error parsing message: $e');
      }
    }
  }
}

class MyHttpOverrides extends HttpOverrides {}

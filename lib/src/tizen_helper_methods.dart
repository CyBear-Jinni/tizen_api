import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:tizen_api/src/api/models/tv.dart';

class TizenHelperMethods {
  static TV? selectedTv;

  static initialize() {
    HttpOverrides.global = _MyHttpOverrides();
  }

  static void log(String message) {
    print('[Tizen API] $message');
  }

  static Future<void> scanNetwork(
      Function(Future<Socket>) socketTaskFunction) async {
    log('Scan started, it may take a while');
    String? ip = await NetworkInfo().getWifiIP();
    log('IP: $ip');
    String subnet = ip!.substring(0, ip.lastIndexOf('.'));
    int port = 8002;
    for (var i = 0; i < 256; i++) {
      String ip = '$subnet.$i';
      Future<Socket> socketTask =
          Socket.connect(ip, port, timeout: const Duration(milliseconds: 50));
      socketTaskFunction.call(socketTask);
    }
    log('Scan completed');
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

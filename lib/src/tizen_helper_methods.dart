import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:tizen_api/src/api/models/tv.dart';

class TizenHelperMethods {
  static Tv? selectedTv;

  static void initialize() {
    HttpOverrides.global = _MyHttpOverrides();
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
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // TODO: Please try to replace this with runZoned in the required area :)
    //  import 'dart:io';  class MyHttpOverrides extends HttpOverrides { @override HttpClient createHttpClient(SecurityContext? context) { return super.createHttpClient(context) ..badCertificateCallback = (X509Certificate cert, String host, int port) => true; } }  void main() { HttpOverrides.runZoned( () { // Your HTTP requests here will use the overridden behavior var client = HttpClient(); // Use your client for specific requests }, createHttpClient: (SecurityContext? context) => MyHttpOverrides().createHttpClient(context), );  // Other HTTP requests outside this zone are unaffected }
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              TizenHelperMethods.selectedTv?.device.ip != null &&
              host == TizenHelperMethods.selectedTv?.device.ip;
  }
}

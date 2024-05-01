import 'dart:io';

import 'package:tizen_api/src/api/models/tv.dart';

class TizenHelperMethods {
  static TV? selectedTv;

  static initialize() {
    HttpOverrides.global = _MyHttpOverrides();
  }

  static void log(String message) {
    print('[Tizen API] $message');
  }

// TODO: Fix does not return results
  // static Stream<TV> scanForDevices() async* {
  //   String? ip = await NetworkInfo().getWifiIP();
  //   const port = 8002;
  //   for (int i = 1; i < 256; i++) {
  //     Socket? socket;
  //     try {
  //       socket = await Socket.connect(ip, port,
  //           timeout: const Duration(milliseconds: 50));
  //       await InternetAddress(socket.address.address).reverse();
  //
  //       final response =
  //           await Dio().get("http://${socket.address.address}:8001/api/v2/");
  //       print("Found ${socket.address.address}");
  //       TV tv = TV.fromJson(response.data as Map<String, dynamic>);
  //       yield (tv);
  //       socket.destroy();
  //     } catch (e) {
  //       socket?.destroy();
  //     }
  //   }
  //
  //   print('Scan completed');
  // }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

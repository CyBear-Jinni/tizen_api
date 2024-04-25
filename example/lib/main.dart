import 'dart:convert';
import 'dart:io';
import 'dart:math' hide log;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizen_api/tizen_api.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late final SharedPreferences preferences;

const applications = {
  "youtube": "111299001912",
  "spotify": "3201606009684",
  "netflix": "11101200001",
  "amazon": "3201512006785",
  "disney": "3201807016598",
};

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              host == "192.168.0.198";
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  preferences = await SharedPreferences.getInstance();
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.purple),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        dividerColor: Colors.purple,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel socket;
  TV? tv;
  TV? _connectedTv;
  List<TV> tvs = [];
  Offset? _dragDelta;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    scanNetwork();
  }

  Future<void> scanNetwork() async {
    await (NetworkInfo().getWifiIP()).then(
      (ip) async {
        final String subnet = ip!.substring(0, ip.lastIndexOf('.'));
        const port = 8002;
        for (var i = 0; i < 256; i++) {
          String ip = '$subnet.$i';
          await Socket.connect(ip, port,
                  timeout: const Duration(milliseconds: 50))
              .then((socket) async {
            await InternetAddress(socket.address.address)
                .reverse()
                .then((value) {
              addDeviceToList(socket.address.address);
            }).catchError((error) {
              addDeviceToList(socket.address.address);
            });
            socket.destroy();
          }).catchError((error) => null);
        }
      },
    );
    print('Done');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          hint: const Text("Select TV"),
          value: tv?.name,
          onChanged: (String? tv) {
            setState(() {
              this.tv = tvs.firstWhere((element) => element.name == tv);
            });
            setupStream();
          },
          items: tvs.map<DropdownMenuItem<String>>((TV tv) {
            return DropdownMenuItem<String>(
              value: tv.name,
              child: Text(
                tv.name,
                style: const TextStyle(fontSize: 30),
              ),
            );
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              _pressKey("KEY_POWER");
            },
          ),
        ],
      ),
      body: !connectedToTV
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_connectedTv != tv
                      ? "Waiting for TV to connect"
                      : "Select TV"),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        hint: const Text("Select Application"),
                        value: null,
                        onChanged: (String? application) {
                          forwardToApplication(application!);
                        },
                        items: applications.keys
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: const TextStyle(fontSize: 30),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: InkWell(
                        child: const Text("HDMI", textAlign: TextAlign.center),
                        onTap: () => _pressKey("KEY_HDMI"),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onVerticalDragStart: (_) => _dragDelta = Offset.zero,
                          onVerticalDragUpdate: (d) {
                            _dragDelta = _dragDelta! + d.delta;

                            const threshold = 30.0;

                            if (_dragDelta!.distance > threshold) {
                              final dir = (_dragDelta!.direction / pi * 2 + 0.5)
                                  .floor();
                              switch (dir) {
                                case -1:
                                  _pressKey("KEY_VOLUP");
                                  _dragDelta =
                                      _dragDelta!.translate(0, threshold);
                                  break;
                                case 1:
                                  _pressKey("KEY_VOLDOWN");
                                  _dragDelta =
                                      _dragDelta!.translate(0, -threshold);
                                  break;
                              }
                            }
                          },
                          onVerticalDragEnd: (_) => _dragDelta = null,
                          onVerticalDragCancel: () => _dragDelta = null,
                          onTap: () => _pressKey("KEY_MUTE"),
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onPanStart: (_) => _dragDelta = Offset.zero,
                          onPanUpdate: (d) {
                            _dragDelta = _dragDelta! + d.delta;
                            //TODO: Delay between key presses
                            const threshold = 60.0;

                            if (_dragDelta!.distance > threshold) {
                              final dir = (_dragDelta!.direction / pi * 2 + 0.5)
                                  .floor();
                              switch (dir) {
                                case 2:
                                case -2:
                                  _pressKey("KEY_LEFT");
                                  _dragDelta = _dragDelta!
                                      .translate(threshold, -_dragDelta!.dy);
                                  break;
                                case -1:
                                  _pressKey("KEY_UP");
                                  _dragDelta = _dragDelta!
                                      .translate(-_dragDelta!.dx, threshold);
                                  break;
                                case 0:
                                  _pressKey("KEY_RIGHT");
                                  _dragDelta = _dragDelta!
                                      .translate(-threshold, -_dragDelta!.dy);
                                  break;
                                case 1:
                                  _pressKey("KEY_DOWN");
                                  _dragDelta = _dragDelta!
                                      .translate(-_dragDelta!.dx, -threshold);
                                  break;
                              }
                            }
                          },
                          onPanEnd: (_) => _dragDelta = null,
                          onPanCancel: () => _dragDelta = null,
                          onTap: () => _pressKey("KEY_ENTER"),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          child: const Center(child: Icon(Icons.arrow_back)),
                          onTap: () => _pressKey("KEY_RETURN"),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          child: const Center(child: Icon(Icons.home_outlined)),
                          onTap: () => _pressKey("KEY_HOME"),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          child: const Center(child: Icon(Icons.pause)),
                          onTap: () => _pressKey("KEY_ENTER"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void setupStream() {
    if (tv == null) return;
    final name = base64Encode("widgy-smart-remote".codeUnits);
    String tvIP = tv!.device.ip;
    String tvName = tv!.name;
    print("connecting to $tvName ($tvIP)...");
    socket = WebSocketChannel.connect(
      Uri(
        scheme: "wss",
        host: tvIP,
        port: 8002,
        path: "/api/v2/channels/samsung.remote.control",
        queryParameters: {
          "name": name,
          "token": preferences.getString("token"),
        },
      ),
    );

    socket.stream.listen((event) {
      print(event);
      if (tv != _connectedTv) {
        setState(() {
          _connectedTv = tv;
        });
      }
      try {
        final json = jsonDecode(event);
        final newToken = json["data"]["token"];

        if (newToken != null) {
          print("got new token $newToken");
          preferences.setString("token", newToken);
        }
      } catch (_) {}
    });
  }

  void forwardToApplication(String application) async {
    if (tv == null) return;
    HapticFeedback.lightImpact();

    await Dio().post(
      "${tv?.uri}applications/${applications[application]!}",
    );
  }

  void addDeviceToList(String ip) async {
    final response = await Dio().get("http://$ip:8001/api/v2/");
    print("Found $ip");
    TV tv = TV.fromJson(response.data as Map<String, dynamic>);
    setState(() {
      tvs.add(tv);
    });
  }

  void _pressKey(Object key) {
    if (tv == null) return;
    print("pressing $key");

    HapticFeedback.lightImpact();

    socket.sink.add(jsonEncode(
      {
        "method": "ms.remote.control",
        "params": {
          "Cmd": "Click",
          "DataOfCmd": key,
          "Option": "false",
          "TypeOfRemote": "SendRemoteKey"
        }
      },
    ));
  }

  bool get connectedToTV => _connectedTv != null && _connectedTv == tv;
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizen/logger.dart';
import 'package:tizen_api/tizen_api.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

late final SharedPreferences preferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  preferences = await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Smart TV Controller',
        theme: ThemeData(primarySwatch: Colors.purple),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.purple,
          dividerColor: Colors.purple,
        ),
        home: const MyHomePage(),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  Tv? _connectedTv;
  List<Tv> tvs = [];
  Offset? _dragDelta;
  String? _token;
  bool isLoading = true;

  bool get connectedToTv =>
      _connectedTv != null && _connectedTv == TizenHelperMethods.selectedTv;

  String? get token => _token ??= preferences.getString('token');

  set token(String? token) {
    _token = token;
    if (token == null) {
      preferences.remove('token');
    } else {
      preferences.setString('token', token);
    }
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    scanNetwork();
  }

  Future<void> scanNetwork() async {
    final String? ip = await NetworkInfo().getWifiIP();
    if (ip == null) {
      return;
    }

    TizenHelperMethods.scanNetwork(ip).listen((tv) {
      setState(() {
        tvs.add(tv);
      });
    }).onDone(() {
      setState(() {
        isLoading = false;
      });
    });
  }

  void _pressKey(KeyCodes key) {
    if (TizenHelperMethods.selectedTv == null) {
      return;
    }
    Logger.log('Sending key: $key');
    HapticFeedback.mediumImpact();
    TizenHelperMethods.selectedTv!.addToSocket(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          hint: const Text('Select TV'),
          value: TizenHelperMethods.selectedTv?.name,
          onChanged: (String? tv) {
            final Tv selectedTvTemp =
                tvs.firstWhere((element) => element.name == tv);
            setState(() {
              TizenHelperMethods.selectedTv = selectedTvTemp;
            });
            setupStream();
          },
          items: tvs
              .map<DropdownMenuItem<String>>(
                (Tv tv) => DropdownMenuItem<String>(
                  value: tv.name,
                  child: Text(tv.name, style: const TextStyle(fontSize: 30)),
                ),
              )
              .toList(),
        ),
        actions: connectedToTv
            ? [
                IconButton(
                  icon: const Icon(Icons.power_settings_new),
                  onPressed: () => _pressKey(KeyCodes.keyPower),
                ),
              ]
            : null,
      ),
      body: connectedToTv
          ? buildConnectedTvUi
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tvs.isNotEmpty)
                    Text(
                      _connectedTv != TizenHelperMethods.selectedTv
                          ? 'Waiting for TV to connect'
                          : 'Select a TV',
                    ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (tvs.isEmpty) ...[
                    const Text('Could not find any TV, you retry'),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: scanNetwork,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget get buildConnectedTvUi => Column(
        children: [
          buildTopRow,
          const Divider(),
          buildGestureControl,
          const Divider(),
          buildBottomRow,
        ],
      );

  Widget get buildTopRow => Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              hint: const Text('Select Application'),
              onChanged: (String? application) {
                if (TizenHelperMethods.selectedTv == null) return;
                HapticFeedback.lightImpact();
                TizenHelperMethods.selectedTv!
                    .forwardToApplication(application!);
              },
              items: Tv.applications.keys
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: InkWell(
              child: const Text('HDMI', textAlign: TextAlign.center),
              onTap: () => _pressKey(KeyCodes.keyHdmi),
            ),
          ),
        ],
      );

  Widget get buildGestureControl => Expanded(
        child: Row(
          children: [
            buildVolumeControl,
            const VerticalDivider(),
            buildNavigationControl,
          ],
        ),
      );

  Widget get buildVolumeControl => Expanded(
        child: GestureDetector(
          onVerticalDragStart: (_) => _dragDelta = Offset.zero,
          onVerticalDragUpdate: (d) => handleVolumeGesture(d),
          onVerticalDragEnd: (_) => _dragDelta = null,
          onVerticalDragCancel: () => _dragDelta = null,
          onTap: () => _pressKey(KeyCodes.keyMute),
        ),
      );

  void handleVolumeGesture(DragUpdateDetails d) {
    _dragDelta = _dragDelta! + d.delta;
    const threshold = 30.0;
    if (_dragDelta!.distance > threshold) {
      final dir = (_dragDelta!.direction / pi * 2 + 0.5).floor();
      switch (dir) {
        case -1:
          _pressKey(KeyCodes.keyVolUp);
          _dragDelta = _dragDelta!.translate(0, threshold);
        case 1:
          _pressKey(KeyCodes.keyVolDown);
          _dragDelta = _dragDelta!.translate(0, -threshold);
      }
    }
  }

  Widget get buildNavigationControl => Expanded(
        flex: 3,
        child: GestureDetector(
          onPanStart: (_) => _dragDelta = Offset.zero,
          onPanUpdate: (d) => handleNavigationGesture(d),
          onPanEnd: (_) => _dragDelta = null,
          onPanCancel: () => _dragDelta = null,
          onTap: () => _pressKey(KeyCodes.keyEnter),
        ),
      );

  void handleNavigationGesture(DragUpdateDetails d) {
    _dragDelta = _dragDelta! + d.delta;
    const threshold = 60.0;
    if (_dragDelta!.distance > threshold) {
      final dir = (_dragDelta!.direction / pi * 2 + 0.5).floor();
      switch (dir) {
        case 2:
        case -2:
          _pressKey(KeyCodes.keyLeft);
          _dragDelta = _dragDelta!.translate(threshold, -_dragDelta!.dy);
        case -1:
          _pressKey(KeyCodes.keyUp);
          _dragDelta = _dragDelta!.translate(-_dragDelta!.dx, threshold);
        case 0:
          _pressKey(KeyCodes.keyRight);
          _dragDelta = _dragDelta!.translate(-threshold, -_dragDelta!.dy);
        case 1:
          _pressKey(KeyCodes.keyDown);
          _dragDelta = _dragDelta!.translate(-_dragDelta!.dx, -threshold);
      }
    }
  }

  Widget get buildBottomRow => SizedBox(
        height: 120,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                child: const Center(child: Icon(Icons.arrow_back)),
                onTap: () => _pressKey(KeyCodes.keyReturn),
              ),
            ),
            Expanded(
              child: InkWell(
                child: const Center(child: Icon(Icons.home_outlined)),
                onTap: () => _pressKey(KeyCodes.keyHome),
              ),
            ),
            Expanded(
              child: InkWell(
                child: const Center(child: Icon(Icons.pause)),
                onTap: () => _pressKey(KeyCodes.keyEnter),
              ),
            ),
          ],
        ),
      );

  void setupStream() {
    TizenHelperMethods.setupStream(token).listen((String? onData) {
      if (TizenHelperMethods.selectedTv != _connectedTv) {
        setState(() {
          _connectedTv = TizenHelperMethods.selectedTv;
        });
        token = onData;
      }
    });
  }
}

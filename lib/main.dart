import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final flutterReactiveBle = FlutterReactiveBle();
  DiscoveredDevice? discoveredDevice;
  StreamSubscription? _subscription;
  StreamSubscription? _stateSubscription;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subscription?.cancel();
    _stateSubscription?.cancel();
    // flutterReactiveBle.clearGattCache(foundDeviceId);
    if (discoveredDevice != null) {
      flutterReactiveBle.clearGattCache(discoveredDevice!.id);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Permission.location.request();
    _subscription = flutterReactiveBle
        .scanForDevices(scanMode: ScanMode.lowLatency, withServices: [], requireLocationServicesEnabled: true)
        .listen((device) {
      //code for handling results
      print("${device.id} | ${device.name}");
      if (device.id == "24:6F:28:D1:9B:12") {
        discoveredDevice = device;
        _subscription?.cancel();
        _stateSubscription = flutterReactiveBle
            .connectToAdvertisingDevice(
                id: discoveredDevice!.id,
                withServices: [],
                prescanDuration: const Duration(seconds: 5),
                servicesWithCharacteristicsToDiscover: {},
                connectionTimeout: const Duration(seconds: 2))
            .listen((connectionState) {
          // Handle connection state updates
          if (connectionState.connectionState == DeviceConnectionState.disconnected) {
            print("disconnected");
          } else if (connectionState.connectionState == DeviceConnectionState.connecting) {
            print("connecting");
          } else if (connectionState.connectionState == DeviceConnectionState.connected) {
            print("connected");
            discoverService();
          }
        }, onError: (dynamic error) {
          // Handle a possible error
        });
      }
    });
  }

  Future discoverService() async {
    if (discoveredDevice != null) {
      var services = await flutterReactiveBle.discoverServices(discoveredDevice!.id);
      for (DiscoveredService service in services) {
        print(service.serviceId);
        for(Uuid uuid in service.characteristicIds){
          print(uuid);
        }

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

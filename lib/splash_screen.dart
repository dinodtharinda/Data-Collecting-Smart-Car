import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:joy_car/DiscoveryPage.dart';



class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return   const DiscoveryPage();
            }
            return const Center(
              child: Text("Bluetooth off"),
            );
          }),
    );
  }
}

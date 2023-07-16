import 'package:flutter/material.dart';
import 'package:joy_car/DiscoveryPage.dart';
import 'package:joy_car/services/bluetooth_service.dart';
import 'package:joy_car/splash_screen.dart';
import 'package:provider/provider.dart';

void main() => runApp(MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (context) => BTService(),
      )
    ], child: const ExampleApplication()));

class ExampleApplication extends StatelessWidget {
  const ExampleApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

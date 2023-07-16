// ignore_for_file: avoid_function_literals_in_foreach_calls, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import '../constants/constant.dart';

class BTService with ChangeNotifier {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubScription;
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? targetCharacteristic;
  bool _isLoading = false;
  String _connectionText = "";

  String get connectionText {
    return _connectionText;
  }

  bool get isLoading {
    return _isLoading;
  }

  void changeText(String text) {
    _connectionText = text;
  }

  void setIsLoading(bool state) {
    _isLoading = state;
  }

  refresh() {
    _connectionText = "Refreshing";
    stopScan();
    disconnectFromDevice();
    startScan();
  }

  startScan() {
    setIsLoading(true);
    changeText("Start Scanning".toUpperCase());
    stopScan();
    flutterBlue.stopScan();

    try {
      scanSubScription = flutterBlue.scan().listen((scanResult) {
        if (scanResult.device.name == Constants.TARGET_DEVICE_NAME) {
          print('DEVICE found'.toUpperCase());
          stopScan();
          print("Found Target Device".toUpperCase());
          targetDevice = scanResult.device;
          connectToDevice();
          notifyListeners();
        }
      }, onDone: () => stopScan());
    } catch (e) {
      stopScan();
    }
  }

  stopScan() {
    if (scanSubScription != null) {
      scanSubScription!.cancel();
      scanSubScription = null;
    }
    print("Scan Stoped!".toUpperCase());
  }

  connectToDevice() async {
    print("Device Connecting".toUpperCase());
    await targetDevice!.disconnect();
    if (targetDevice == null) return;
    await targetDevice!.connect();
    print('DEVICE CONNECTED'.toUpperCase());
    discoverServices();
    notifyListeners();
  }

  disconnectFromDevice() {
    if (targetDevice == null) return;
    targetDevice!.disconnect();
    print("Device Disconnected".toUpperCase());
    notifyListeners();
  }

  discoverServices() async {
    if (targetDevice == null) return;
    List<BluetoothService> services = await targetDevice!.discoverServices();
    services.forEach((service) {
      // do something with service
      if (service.uuid.toString() == Constants.SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == Constants.CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristic;
            writeData("Hi there, ESP32!!");
            writeData("0, 0");

            _connectionText =
                "All Ready with ${targetDevice!.name}".toUpperCase();
            setIsLoading(false);
            notifyListeners();
          }
        });
      }
    });
  }

 
  writeData(String data) async {
    if (targetCharacteristic == null) return;
    List<int> bytes = utf8.encode(data);
    try {
      await targetCharacteristic!.write(bytes); 
     
read();
    } catch (e) {
      if (data == "0.00 0.00") {
        writeData(data);
        print(".......");
      }
    }
  }


 Stream read(){
    Stream<List<int>> c =  targetCharacteristic!.value;
    return  c;
  }
}

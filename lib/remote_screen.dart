// ignore_for_file: avoid_print, prefer_const_declarations, prefer_typing_uninitialized_variables, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:joy_car/Joystick/views/joystick_view.dart';
import 'package:joy_car/services/bluetooth_service.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;
  BTService btService;
  ChatPage({
    Key? key,
    required this.server,
    required this.btService,
  }) : super(key: key);

  @override
  _ChatPage createState() => _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  var connection; //BluetoothConnection

  List<_Message> messages = [];
  String _messageBuffer = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  bool isConnecting = true;
  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected()) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  ScrollController _scrollController = ScrollController();

  _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  double servoValue = 90;
  double speedValue = 101;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    Future onDirectionChanged(double degrees, double distance) async {
      String data =
          "${degrees.toStringAsFixed(2)} ${distance.toStringAsFixed(2)}";
      print(data);
      widget.btService.writeData(data);
    }

    final List<Row> list = messages.map((_message) {
      return Row(
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 4.0, left: 4.0, right: 4.0),
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
            child: Row(
              mainAxisAlignment: _message.whom != clientID
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                Text(
                    (text) {
                      return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                    }(_message.whom != clientID
                        ? "${_message.text.trim()}"
                        : "${_message.text.trim()}"),
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255))),
              ],
            ),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black,
          title: (isConnecting
              ? Text('Connecting chat to ${widget.server.name}...')
              : isConnected()
                  ? Text('Live chat with ${widget.server.name}')
                  : Text('Chat log with ${widget.server.name}'))),
      body: isConnecting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                SizedBox(height: 30,),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        border: Border.all(width: 1),
                        borderRadius: BorderRadius.circular(20)),
                    height: 250,
                    child: ListView(
                        //  reverse: true,
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(12.0),
                        controller: _scrollController,
                        children: list),
                  ),
                ),
                 SizedBox(height: 30,),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green
                                  , // Sets color for all the descendant ElevatedButtons
                            ),
                            onPressed: () {
                              _sendMessage("Hello ESP32");
                              widget.btService.writeData("Hello");
                            },
                            child: const Text("Hello ESP32")),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red
                                  , // Sets color for all the descendant ElevatedButtons
                            ),
                            onPressed: () {
                              _sendMessage("Request Temp And Humidity");
                              widget.btService
                                  .writeData("checkTempAndHumidity");
                            },
                            child: const Text("check Temp And Humidity")),
                        ElevatedButton(
                           style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange
                                  , // Sets color for all the descendant ElevatedButtons
                            ),
                            onPressed: () {
                              _sendMessage("Request Gas");
                              widget.btService.writeData("checkGas");
                            },
                            child: const Text("check Gas")),
                      ],
                    ),
                    const SizedBox(height: 30,),
                    JoystickView(
                    backgroundColor: Colors.red,
                        interval: const Duration(milliseconds: 150),
                        opacity: 0.9,
                        onDirectionChanged: onDirectionChanged),
                  ],
                ),
                // Row(
                //   children: <Widget>[
                //     Flexible(
                //       child: Container(
                //         margin: const EdgeInsets.only(left: 16.0),
                //         child: TextField(
                //           style: const TextStyle(fontSize: 15.0),
                //           controller: textEditingController,
                //           decoration: InputDecoration.collapsed(
                //             hintText: isConnecting
                //                 ? 'Wait until connected...'
                //                 : isConnected()
                //                     ? 'Type your message...'
                //                     : 'Chat got disconnected',
                //             hintStyle: const TextStyle(color: Colors.grey),
                //           ),
                //           enabled: isConnected(),
                //         ),
                //       ),
                //     ),
                //     Container(
                //       margin: const EdgeInsets.all(8.0),
                //       child: IconButton(
                //           icon: const Icon(Icons.send),
                //           onPressed: isConnected()
                //               ? () => _sendMessage(textEditingController.text)
                //               : null),
                //     ),
                //   ],
                // )
              ],
            ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    for (var byte in data) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    }
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    var nowtime = DateTime.now();
    String time = DateFormat.Hm().format(nowtime);
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : "$_messageBuffer$time • ${dataString.substring(0, index)}",
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    var nowtime = DateTime.now();
    String time = DateFormat.Hm().format(nowtime);
    text = text.trim();
    textEditingController.clear();

    if (text.isNotEmpty) {
      try {
        connection.output.add(utf8.encode("$text\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text + " • $time "));
        });

        // Future.delayed(const Duration(milliseconds: 333)).then((_) {
        //   listScrollController.animateTo(
        //       listScrollController.position.minScrollExtent,
        //       duration: const Duration(milliseconds: 333),
        //       curve: Curves.easeOut);
        // });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  bool isConnected() {
    return connection != null && connection.isConnected;
  }
}

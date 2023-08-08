import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intervent_sab_bluetooth/bluetooth_devices.dart';
import 'package:intervent_sab_bluetooth/percent_indicator.dart';

enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothConnectionState _btStatus = BluetoothConnectionState.disconnected;
  BluetoothConnection? connection;
  String _messageBuffer = '';
  double? percentValue;
  double? degreeValue;
  bool _isWatering = false;

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
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
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    var message = '';
    if (~index != 0) {
      message = backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString.substring(0, index);
      _messageBuffer = dataString.substring(index);
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }

    // calculate percentage from message
    // analog 10 bit
    if (message.isEmpty) return; // to avoid format exception
    var values = message.trim().split(',');
    if (values.length == 2) {
      double? analogMessage = double.tryParse(values[1]);
      double? analogDegree = double.tryParse(values[0]);

      setState(() {
        var percent = (analogMessage ?? 0);
        percentValue = percent; // inverse percent
        degreeValue = analogDegree;
      });
    }
  }

  // Function to handle the disconnection process
  void _disconnect() async {
    if (connection != null) {
      try {
        await connection!.close();
        connection = null;
        setState(() {
          _btStatus = BluetoothConnectionState.disconnected;
        });
      } catch (error) {
        print('Error while disconnecting: $error');
        setState(() {
          _btStatus = BluetoothConnectionState.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(2.5),
            child: IconButton(
              icon: const Icon(
                Icons.settings_bluetooth,
                size: 28,
              ),
              onPressed: () async {
                BluetoothDevice? device = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BluetoothDevices()),
                );

                if (device == null) return;

                print('Connecting to device...');
                setState(() {
                  _btStatus = BluetoothConnectionState.connecting;
                });

                BluetoothConnection.toAddress(device.address)
                    .then((_connection) {
                  print('Connected to the device');
                  connection = _connection;
                  setState(() {
                    _btStatus = BluetoothConnectionState.connected;
                  });

                  connection!.input!.listen(_onDataReceived).onDone(() {
                    setState(() {
                      _btStatus = BluetoothConnectionState.disconnected;
                    });
                  });
                }).catchError((error) {
                  print('Cannot connect, exception occurred');
                  print(error);

                  setState(() {
                    _btStatus = BluetoothConnectionState.error;
                  });
                });
              },
            ),
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                switch (_btStatus) {
                  case BluetoothConnectionState.disconnected:
                    return PercentIndicator.disconnected();
                  case BluetoothConnectionState.connecting:
                    return PercentIndicator.connecting();
                  case BluetoothConnectionState.connected:
                    return PercentIndicator.connected(
                      percent: percentValue ?? 0,
                      degree: degreeValue ?? 0,
                    );
                  case BluetoothConnectionState.error:
                    return PercentIndicator.error();
                }
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                String text = 'Checking Connection';

                setState(() => _isWatering = true);

                if (text.isNotEmpty) {
                  try {
                    connection!.output
                        .add(Uint8List.fromList(utf8.encode("$text\r\n")));
                    await connection!.output.allSent;
                  } finally {
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() => _isWatering = false);
                    });
                  }
                }
              },
              child: const Text('Get Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Call the disconnect function when the button is pressed
                _disconnect();
              },
              child: const Text('Disconnect'),
            ),
            SizedBox(
              height: 160,
              width: 300,
              child: Image.asset(
                'assets/logo2.png',
              ),
            )
          ],
        ),
      ),
    );
  }
}

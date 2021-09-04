import 'dart:async';
import 'dart:convert' show utf8;
import 'package:control_pad/models/pad_button_item.dart';
import 'package:control_pad/control_pad.dart';
import 'package:control_pad/models/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_app_joypad_ble/page2.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:lite_rolling_switch/lite_rolling_switch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MainScreen());
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orbitro Motor Control',
      debugShowCheckedModeBanner: false,
      home: JoyPad(),
      theme: ThemeData.light(),
    );
  }
}

class JoyPad extends StatefulWidget {
  @override
  _JoyPadState createState() => _JoyPadState();
}

class _JoyPadState extends State<JoyPad> {
  final String SERVICE_UUID = "eb36d2c8-e3da-41f7-8120-2664c83fa432";
  final String CHARACTERISTIC_UUID = "433d109a-a336-4479-bfa5-7c29097d65ca";
  final String TARGET_DEVICE_NAME = "Kutar bilisim";
  double _currentSliderValue = 0;
  double _currentSliderValue1 = 0;
  final myController = TextEditingController();
  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubScription;

  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;
  BluetoothDescriptor descriptor;
  String connectionText = "";

  @override
  void initState() {
    super.initState();
    startScan();
  }

  startScan() {
    setState(() {
      connectionText = "Tarama yapılıyor";
    });

    scanSubScription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name == TARGET_DEVICE_NAME) {
        print('Cihazlar bulundu');
        stopScan();
        setState(() {
          connectionText = "Hedef cihaz bulundu";
        });

        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

  stopScan() {
    scanSubScription?.cancel();
    scanSubScription = null;
  }

  reset(){
    stopScan();
    startScan();
  }

  connectToDevice() async {
    if (targetDevice == null) return;

    setState(() {
      connectionText = "Cihaz Bağlanılıyor...";
    });

    await targetDevice.connect();
    print('Cihaz Bağlandı');
    setState(() {
      connectionText = "Cihaz Bağlandı";
    });

    discoverServices();
  }

  disconnectFromDevice() {
    if (targetDevice == null) return;

    targetDevice.disconnect();

    setState(() {
      connectionText = "Cihaz bağlantısı koptu..";
    });
  }

  discoverServices() async {
    if (targetDevice == null) return;

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      // do something with service
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristic;
            writeData(" ESP32!!");
            setState(() {
              connectionText = "Bağlı olan cihazlar: ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

  writeData(String data) {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    targetCharacteristic.write(bytes);
  }

  @override
  Widget build(BuildContext context) {
    JoystickDirectionCallback onDirectionChanged(
        double degrees, double distance) {
      String data =
          "Derece: ${degrees.toStringAsFixed(2)}, Uzaklık : ${distance.toStringAsFixed(2)}";
      print(data);
      writeData(data);
    }

    PadButtonPressedCallback padBUttonPressedCallback(
        int buttonIndex, Gestures gesture) {
      String data = "Button : ${buttonIndex}";
      print(data);
      writeData(data);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(connectionText),
        actions: <Widget>[
          PopupMenuButton(
            itemBuilder: (content) => [
              PopupMenuItem(
                value: 1,
                child: Text("Sensorler"),
              ),
              PopupMenuItem(
                value: 2,
                child: Text("Komut"),
              ),
            ],
            onSelected: (int menu) {
              if (menu == 1) {
                Navigator.push((context),
                    MaterialPageRoute(builder: (context) => page2()));
              } else if (menu == 2) {
                Navigator.push((context),
                    MaterialPageRoute(builder: (context) => page2()));
              }
            },
          ),
        ],
      ),
      body: Container(
        child: targetCharacteristic == null
            ? Column(children: <Widget>[
                Center(
                  child: Container(
                    margin: EdgeInsets.all(20),
                    child: Text(
                      "Bekleniyor...",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(20),
                    child: Center(
                        child: Text(
                  "Eğer bir Sorun Yaşarsanız Reset Atabilirsiniz",
                  style: TextStyle(fontSize: 12, color: Colors.black26),
                ))),
                ElevatedButton(
                  child: Text('RESET'), 
                  style: ElevatedButton.styleFrom(
                    primary: Colors.teal,
                    onPrimary: Colors.white,
                    onSurface: Colors.grey,
                  ),
                  onPressed: () {
                    reset();
                  },
                )
              ])
            : PageView(children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    JoystickView(
                      onDirectionChanged: onDirectionChanged,
                    ),
                    PadButtonsView(
                      buttons: [
                        PadButtonItem(
                            index: 361,
                            buttonText: "90",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 362,
                            buttonText: "180",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 363,
                            buttonText: "270",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 364,
                            buttonText: "0",
                            pressedColor: Colors.black45),
                      ],
                      padButtonPressedCallback: padBUttonPressedCallback,
                    ),
                    PadButtonsView(
                      buttons: [
                        PadButtonItem(
                            index: 365,
                            buttonText: "RIGHT",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 366,
                            buttonText: "-",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 367,
                            buttonText: "LEFT",
                            pressedColor: Colors.black45),
                        PadButtonItem(
                            index: 368,
                            buttonText: "+",
                            pressedColor: Colors.black45),
                      ],
                      padButtonPressedCallback: padBUttonPressedCallback,
                    ),
                  ],
                ),
                Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      child: Center(
                        child: Text(
                          "Max Speed",
                          style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    Container(
                      width: 400,
                      height: 80,
                      child: Slider(
                        value: _currentSliderValue,
                        min: 0,
                        max: 180,
                        divisions: 180,
                        label: _currentSliderValue.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _currentSliderValue = value;
                            writeData(value.toString());
                          });
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        "Max Torque",
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      width: 400,
                      height: 80,
                      child: Slider(
                        value: _currentSliderValue1,
                        min: 0,
                        max: 200,
                        divisions: 200,
                        label: _currentSliderValue1.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _currentSliderValue1 = value;
                            writeData(value.toString());
                          });
                        },
                      ),
                    ),
                    Container(
                      width: 130,
                      height: 50,
                      child: LiteRollingSwitch(
                        value: true,
                        textOn: "Saat Yönü",
                        textOff: "Tersi",
                        colorOn: Colors.greenAccent,
                        colorOff: Colors.redAccent,
                        iconOn: Icons.rotate_right,
                        iconOff: Icons.rotate_left,
                        textSize: 15,
                        onChanged: (bool state) {
                          writeData(state.toString());
                        },
                      ),
                    ),
                  ],
                ),
                Column(children: <Widget>[
                  Container(
                     margin: EdgeInsets.only(top:30),
                    child: Center(
                      child: Text(
                        "Command Box",
                        style: TextStyle(
                            color: Colors.black54,
                            fontSize: 24,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 50),
                    width: 300,
                    height: 80,
                    child: TextField(
                      controller: myController,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 50, left: 300),
                    width: 50,
                    height: 50,
                    child: FloatingActionButton(
                      // When the user presses the button, show an alert dialog containing
                      // the text that the user has entered into the text field.
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                          return AlertDialog(
                              // Retrieve the text the that user has entered by using the
                              // TextEditingController.
                              content: Text(
                                  "Gönderilen Komut : ${myController.text}"),
                            );
                          },
                        );
                        writeData(myController.text);
                      },
                      tooltip: 'Show me the value!',
                      child: Icon(Icons.send),
                    ),
                  ),
                ]),
              ]),
      ),
    );
  }
}

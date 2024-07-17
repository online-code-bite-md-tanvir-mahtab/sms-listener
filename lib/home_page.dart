import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:testmessage/api_list_screen.dart';
import 'package:testmessage/database/database_helper.dart';
import 'package:testmessage/model/api.dart';
import 'package:testmessage/model/sms.dart';
import 'package:testmessage/sms_list_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  TextEditingController api_controller = TextEditingController();

  static const platform = MethodChannel('sms.receiver.channel');
  String sms = 'No SMS';
  String sender = "No Sender";
  List<SMS> smsList = [];
  List<API> apiList = [];

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        final smsData = call.arguments as Map;
        final String sender = smsData['sender'];
        final String message = smsData['message'];
        handleSmsData(sender, message);
      }
    });
    fetchSmsFromDatabase();
    requestSmsPermission();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        sendPendingSms();
      }
    });
  }

  Future<void> requestSmsPermission() async {
    try {
      await platform.invokeMethod('receive_sms');
    } on PlatformException catch (e) {
      print("Failed to request SMS permission: '${e.message}'.");
    }
  }

  Future<void> handleSmsData(String sender, String message) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      // No internet connection
      saveSmsToDatabase(sender, message);
    } else {
      print("The internet is connected!!");
      // it will check if there is any msg saved in the database or not
      // if its saved then it will loop through and send all the msg to the api
      final List<SMS> smsList = await DatabaseHelper().getSms();
      if (smsList.isNotEmpty) {
        for (SMS sms in smsList) {
          await sendSmsData(sms.sender, sms.message);
        }
        setState(() {
          DatabaseHelper().clearSmsTable();
        });
      }
      // Internet connection available
      bool success = await sendSmsData(sender, message);
      if (!success) {
        // If sending fails, save to database
        saveSmsToDatabase(sender, message);
      }
    }
  }

  Future<bool> sendSmsData(String mySender, String myMessage) async {
    bool issended = false;
    if (apiList.isNotEmpty) {
      for (var uris in apiList) {
        final url = uris.url;
        print("the url: ${uris}");
        final headers = {'Content-Type': 'application/json'};
        final body = jsonEncode({
          'data': {'sender': mySender, 'message': myMessage}
        });

        try {
          final response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body,
          );

          if (response.statusCode == 200) {
            print('Request was successful');
            issended = true; // Successful
          } else {
            print('Request failed with status: ${response.statusCode}');
            issended = false; // Failed
          }
        } catch (e) {
          print('Error sending POST request: $e');
          issended = false; // Failed
        }
      }
    } else {
      final url = 'https://sfs-app-test-server.vercel.app/sms/sync';
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({
        'data': {'sender': mySender, 'message': myMessage}
      });

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        );

        if (response.statusCode == 200) {
          print('Request was successful');
          issended = true; // Successful
        } else {
          print('Request failed with status: ${response.statusCode}');
          issended = false; // Failed
        }
      } catch (e) {
        print('Error sending POST request: $e');
        issended = false; // Failed
      }
    }
    return issended;
  }

  Future<void> saveSmsToDatabase(String sender, String message) async {
    final sms = SMS(sender: sender, message: message);
    await _dbHelper.insertSms(sms);
    fetchSmsFromDatabase();
  }

  Future<void> saveApiToDatabase(String myUrl) async {
    final api = API(name: '', url: myUrl);
    await _dbHelper.insertApi(api);
    fetchApiFromDatabase();
    api_controller.clear();
  }

  Future<void> fetchSmsFromDatabase() async {
    final smsList = await _dbHelper.getSms();
    setState(() {
      this.smsList = smsList;
    });
  }

  Future<void> fetchApiFromDatabase() async {
    final apiList = await _dbHelper.getApis();
    setState(() {
      this.apiList = apiList;
    });
  }

  Future<void> sendPendingSms() async {
    final List<SMS> smsList = await DatabaseHelper().getSms();
    if (smsList.isNotEmpty) {
      for (SMS sms in smsList) {
        bool success = await sendSmsData(sms.sender, sms.message);
        if (success) {
          setState(() {
            DatabaseHelper().clearSmsTable();
          });
          ;
        }
      }
      setState(() {
        fetchSmsFromDatabase();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: api_controller,
                      decoration: InputDecoration(
                        hintText: 'Enter Api url',
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    SizedBox(height: 20.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                saveApiToDatabase(api_controller.text);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 15.0),
                                primary: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text(
                                "Add API",
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ApiListScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 15.0),
                                primary:
                                    const Color.fromARGB(255, 127, 170, 245),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text(
                                "Check API List",
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// const Text(
                //   'Incoming message :',
                //   style: TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.blueAccent),
                // ),
                // const SizedBox(height: 10),
                // Text(
                //   sender,
                //   style: const TextStyle(fontSize: 18, color: Colors.black54),
                // ),
                // Text(
                //   sms,
                //   style: const TextStyle(fontSize: 18, color: Colors.black54),
                // ),
                // const SizedBox(height: 20),
                // const Text(
                //   'Stored messages :',
                //   style: TextStyle(
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.blueAccent),
                // ),
                // const SizedBox(height: 10),
                // ListView.builder(
                //   itemCount: smsList.length,
                //   itemBuilder: (context, index) {
                //     return ListTile(
                //       title: Text(smsList[index].sender),
                //       subtitle: Text(smsList[index].message),
                //     );
                //   },
                // ),
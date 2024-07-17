import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:testmessage/database/database_helper.dart';
import 'package:testmessage/model/sms.dart';
import 'package:http/http.dart' as http;

class SavedMessageScreen extends StatefulWidget {
  const SavedMessageScreen({Key? key}) : super(key: key);

  @override
  _SavedMessageScreenState createState() => _SavedMessageScreenState();
}

class _SavedMessageScreenState extends State<SavedMessageScreen> {
  late Future<List<SMS>> _messageListFuture;

  @override
  void initState() {
    super.initState();
    _refreshMessageList();
  }

  Future<void> _refreshMessageList() async {
    setState(() {
      _messageListFuture = DatabaseHelper().getSms();
    });
  }

  Future<void> _uploadSmsMessages(BuildContext context) async {
    try {
      final List<SMS> smsList = await DatabaseHelper().getSms();
      for (SMS sms in smsList) {
        await sendSmsData(sms.sender, sms.message);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS messages uploaded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading SMS messages: $e')),
      );
    }
  }

  Future<void> _uploadSms(SMS sms) async {
    await sendSmsData(sms.sender, sms.message);
  }

  Future<bool> sendSmsData(String mySender, String myMessage) async {
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
        print('Request was successful all api uploaded');
        return true; // Successful
      } else {
        print('Request failed with status: ${response.statusCode}');
        return false; // Failed
      }
    } catch (e) {
      print('Error sending POST request: $e');
      return false; // Failed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Messages'),
      ),
      floatingActionButton:
          SizedBox.shrink(), // Remove the floating action button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Add your onPressed logic here
            _uploadSmsMessages(context);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
            child: Text(
              'Upload to api\'s',
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // Customize button background color
            elevation: 6.0, // Customize button elevation
          ),
        ),
      ),
      body: Center(
        child: FutureBuilder<List<SMS>>(
          future: _messageListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final messages = snapshot.data!;
              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Card(
                    child: ListTile(
                      title: Text(message.sender),
                      subtitle: Text(message.message),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

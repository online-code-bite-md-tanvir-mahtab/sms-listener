import 'package:flutter/material.dart';
import 'package:testmessage/database/database_helper.dart';
import 'package:testmessage/model/api.dart';
import 'package:testmessage/sms_list_screen.dart';

class ApiListScreen extends StatefulWidget {
  const ApiListScreen({Key? key}) : super(key: key);

  @override
  _ApiListScreenState createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen> {
  late Future<List<API>> _apiListFuture;

  @override
  void initState() {
    super.initState();
    _refreshApiList();
  }

  Future<void> _refreshApiList() async {
    setState(() {
      _apiListFuture = DatabaseHelper().getApis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API List'),
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                DatabaseHelper().clearApiTable();
                _apiListFuture = DatabaseHelper().getApis();
              });
            },
            icon: Icon(Icons.clear),
          )
        ],
      ),
      body: Center(
        child: FutureBuilder<List<API>>(
          future: _apiListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final apis = snapshot.data!;
              return ListView.builder(
                itemCount: apis.length,
                itemBuilder: (context, index) {
                  final api = apis[index];
                  return Card(
                    child: ListTile(
                      title: Text(api.name),
                      subtitle: Text(api.url),
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

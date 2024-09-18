import 'package:flutter/material.dart';
import 'client_list_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Client Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ClientListPage(),
    );
  }
}

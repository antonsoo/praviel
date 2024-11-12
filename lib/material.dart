import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblical Languages'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Biblical Hebrew'),
            onTap: () {
              // Navigate to Biblical Hebrew module
            },
          ),
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Koine Greek'),
            onTap: () {
              // Navigate to Koine Greek module
            },
          ),
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Old Church Slavonic'),
            onTap: () {
              // Navigate to Old Church Slavonic module
            },
          ),
        ],
      ),
    );
  }
}


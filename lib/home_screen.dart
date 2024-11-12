import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BiblicalLanguages'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Biblical Hebrew'),
            onTap: () {
              Navigator.pushNamed(context, '/hebrew');
            },
          ),
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Koine Greek'),
            onTap: () {
              Navigator.pushNamed(context, '/greek');
            },
          ),
          ListTile(
            leading: Icon(Icons.book, color: Colors.indigo),
            title: Text('Old Church Slavonic'),
            onTap: () {
              Navigator.pushNamed(context, '/slavonic');
            },
          ),
        ],
      ),
    );
  }
}


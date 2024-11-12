import 'package:flutter/material.dart';

class HebrewHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblical Hebrew'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Biblical Hebrew Module',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

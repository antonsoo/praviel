import 'package:flutter/material.dart';

class SlavonicHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Old Church Slavonic'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Old Church Slavonic Module',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

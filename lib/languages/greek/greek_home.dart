import 'package:flutter/material.dart';

class GreekHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblical Greek'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Biblical Greek Module',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

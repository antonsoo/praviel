import 'package:flutter/material.dart';
import 'package:biblical_languages_app/languages/hebrew/hebrew_home.dart';
import 'package:biblical_languages_app/languages/greek/greek_home.dart';
import 'package:biblical_languages_app/languages/slavonic/slavonic_home.dart';

void main() {
  runApp(BiblicalLanguagesApp());
}

class BiblicalLanguagesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblical Languages App',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/home': (context) => HomeScreen(), // HomeScreen is now defined below
	'/hebrew': (context) => HebrewHome(),
	'/greek': (context) => GreekHome(),
	'/slavonic': (context) => SlavonicHome(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 150,
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome to the Biblical Languages App. May God bless your learning experience.',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Learn Biblical languages and deepen your faith.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home'); // Navigate to HomeScreen
                  },
                  child: Text('Get Started'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Define HomeScreen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen! God bless!'),
      ),
    );
  }
}


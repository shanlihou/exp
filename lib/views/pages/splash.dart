import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    initAsync();
  }

  void initAsync() async {
    SharedPreferences.getInstance().then((prefs) {
      String path = prefs.getString('currentPath') ?? '';
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => HomePage(path: path)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Splash Page')),
    );
  }
}

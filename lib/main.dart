import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'common/utils.dart';
import 'views/pages/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDirectory();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const SplashPage(),
        );
      },
    );
  }
}

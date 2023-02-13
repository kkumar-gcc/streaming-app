import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ombre/auth/google_provider.dart';
import 'package:ombre/screens/go_live_screen.dart';
import 'package:ombre/screens/home_screen.dart';
import 'package:ombre/screens/login_screen.dart';

import 'package:ombre/screens/welcome_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoogleSignInProvider(),
      child: MaterialApp(
        title: 'Ombre Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          WelcomeScreen.routeName: (context) => const WelcomeScreen(),
          GoLiveScreen.routeName: (context) => const GoLiveScreen(),
        },
        home: const HomeScreen(),
      ),
    );
  }
}

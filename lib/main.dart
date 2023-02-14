import 'package:flutter/foundation.dart';
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
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: "AIzaSyBkW25zTNAEOBivIHaQWWQj69fXV8qEZYE",
      authDomain: "ombre-demo.firebaseapp.com",
      projectId: "ombre-demo",
      storageBucket: "ombre-demo.appspot.com",
      messagingSenderId: "948402163540",
      appId: "1:948402163540:web:806f68f4ffad01590642c1",
      measurementId: "G-WJKGT7DZS4",
    ));
  } else {
    await Firebase.initializeApp();
  }

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
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSwatch(
            cardColor: const Color(0xff01011F),
            accentColor: const Color(0xff01011F),
            primaryColorDark: const Color(0xff01011F),
            backgroundColor: const Color(0xff8C8AFA),
          ),
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

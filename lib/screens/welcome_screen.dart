import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ombre/auth/google_provider.dart';
import 'package:ombre/screens/go_live_screen.dart';
import 'package:ombre/screens/login_screen.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  static const routeName = "/welcome";
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        elevation: 2.0,
        title: const Text("Discover"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(FontAwesomeIcons.arrowRightFromBracket),
            tooltip: 'logout',
            onPressed: () {
              final provider =
                  Provider.of<GoogleSignInProvider>(context, listen: false);
              print(user!.uid);
              provider.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(user!.photoURL!),
          ),
          Text('Name: ${user!.displayName!}'),
          ElevatedButton.icon(
            onPressed: () {
              final provider =
                  Provider.of<GoogleSignInProvider>(context, listen: false);
              provider.logout();
            },
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
            label: const Text("logout"),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, GoLiveScreen.routeName);
        },
        elevation: 2.0,
        tooltip: "Go Live",
        child: const Icon(FontAwesomeIcons.plus),
      ),
    );
  }
}

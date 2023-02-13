import 'package:firebase_auth/firebase_auth.dart';

class User {
  final String uid;
  final String name;
  final String email;
  User({
    required this.uid,
    required this.name,
    required this.email,
  });
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}

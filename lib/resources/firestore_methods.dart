import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:ombre/models/livestream.dart';
import 'package:ombre/resources/storage_methods.dart';
import 'package:ombre/utils/utils.dart';

class FirestoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageMethods _storageMethods = StorageMethods();
  String channelId = '';
  Future<String> startLiveStream(
      BuildContext context, String title, Uint8List? image) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (title.isNotEmpty && image != null) {
        channelId = '${user!.uid}${user.displayName}';
        if (!((await _firestore.collection('livestream').doc(channelId).get())
            .exists)) {
          String thumbnailUrl = await _storageMethods.uploadImageInStorage(
            'livestream-thumbnails',
            image,
            user.uid,
          );

          LiveStream liveStream = LiveStream(
            title: title,
            image: thumbnailUrl,
            uid: user.uid,
            name: user.displayName!,
            startedAt: DateTime.now(),
            viewers: 0,
            channelId: channelId,
          );
          _firestore
              .collection('livestream')
              .doc(channelId)
              .set(liveStream.toMap());
        } else {
          showSnackBar(context, "max limit reached.");
        }
      } else {
        showSnackBar(context, "Please enter all the fields");
      }
    } on FirebaseException catch (e) {
      showSnackBar(context, e.message!);
    }
    return channelId;
  }
}

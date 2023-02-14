import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ombre/resources/firestore_methods.dart';
import 'package:ombre/screens/broadcast_screen.dart';
import 'package:ombre/utils/utils.dart';
import 'package:ombre/widgets/custom_textfield.dart';

class GoLiveScreen extends StatefulWidget {
  static const routeName = "/go-live";
  const GoLiveScreen({Key? key}) : super(key: key);

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  final TextEditingController _titleController = TextEditingController();
  Uint8List? thumbnailImage;
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  goLiveStream() async {
    String channelId = await FirestoreMethods()
        .startLiveStream(context, _titleController.text, thumbnailImage);
    if (channelId.isNotEmpty) {
      showSnackBar(context, 'Livestream has started successfully!');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BroadcastScreen(
            isBroadcaster: true,
            channelId: channelId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: const Color(0xff8C8AFA),
        foregroundColor: const Color(0xff01011F),
        title: const Text("Discover"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(FontAwesomeIcons.video),
            tooltip: 'Go Live',
            onPressed: goLiveStream,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22.0,
                vertical: 10.0,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      Uint8List? pickedImage = await pickImage();
                      if (pickedImage != null) {
                        setState(() {
                          thumbnailImage = pickedImage;
                        });
                      }
                    },
                    child: thumbnailImage != null
                        ? SizedBox(
                            height: 300,
                            child: Image.memory(thumbnailImage!),
                          )
                        : DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(10),
                            dashPattern: const [10, 4],
                            strokeCap: StrokeCap.round,
                            color: const Color(0xff01011F),
                            child: Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xff01011F).withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    FontAwesomeIcons.folder,
                                    color: Color(0xff01011F),
                                    size: 40,
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Text(
                                    'Select your thumbnail',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xff01011F),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      CustomTextField(
                        labelText: 'title',
                        textEditingController: _titleController,
                        textColor: const Color(0xff01011F),
                        accentColor: const Color(0xff01011F),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

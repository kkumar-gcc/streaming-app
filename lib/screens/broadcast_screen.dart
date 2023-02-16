import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ombre/models/livestream.dart';
import 'package:ombre/resources/firestore_methods.dart';
import 'package:ombre/widgets/loading_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ombre/config/appid.dart';
import 'package:http/http.dart' as http;

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;

  const BroadcastScreen(
      {Key? key, required this.isBroadcaster, required this.channelId})
      : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  List<int> remoteUid = [];
  late final RtcEngine _engine;
  bool switchCamera = true;
  bool isMuted = false;
  bool isCameraOn = true;
  bool isAgoraInitialised = false;
  @override
  void initState() {
    super.initState();
    initAgora();
  }

  final user = FirebaseAuth.instance.currentUser;
  String baseUrl = "https://ombre-server-production.up.railway.app";
  String? token;

  Future<void> getToken() async {
    final res = await http.get(
      Uri.parse(
        ('$baseUrl/rtc/${widget.channelId}/publisher/userAccount/${user!.uid}/'),
      ),
    );
    if (res.statusCode == 200) {
      setState(() {
        token = res.body;
        token = jsonDecode(token!)['rtcToken'];
      });
    } else {
      debugPrint('Failed to fetch token');
    }
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();
    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    _engine.registerEventHandler(
      RtcEngineEventHandler(onJoinChannelSuccess:
          (RtcConnection connection, int elapsed) {
        debugPrint("local user ${connection.localUid} joined");
        setState(() {
          // remoteUid.add(connection.localUid!);
        });
      }, onUserJoined: (RtcConnection connection, int uid, int elapsed) {
        debugPrint("remote user $uid joined");
        setState(() {
          remoteUid.add(uid);
        });
      }, onUserOffline:
          (RtcConnection connection, int uid, UserOfflineReasonType reason) {
        debugPrint("remote user $uid left channel");
        setState(() {
          remoteUid.removeWhere((element) => element == uid);
        });
      }, onTokenPrivilegeWillExpire:
          (RtcConnection connection, String token) async {
        await getToken();
        await _engine.renewToken(token);
        debugPrint(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
      }, onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        setState(() {
          remoteUid.clear();
        });
      }),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    if (widget.isBroadcaster) {
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
    setState(() {
      isAgoraInitialised = true;
    });
    await getToken();
    await _engine.joinChannelWithUserAccount(
      token: token!,
      channelId: widget.channelId,
      userAccount: user!.uid,
    );
  }

  void _switchCamera() {
    _engine
        .switchCamera()
        .then((value) => {
              setState(() => {switchCamera = !switchCamera})
            })
        .catchError((err) {
      debugPrint('switchCamera $err');
    });
  }

  void _onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    await _engine.muteLocalAudioStream(isMuted);
  }

  void _onToggleCamera() async {
    setState(() {
      isCameraOn = !isCameraOn;
    });
    await _engine.muteLocalVideoStream(isCameraOn);
  }

  _leaveChannel() async {
    await _engine.leaveChannel();
    if ('${user!.uid}${user!.displayName}' == widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updateViewCount(widget.channelId, false);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          await _leaveChannel();
          return Future.value(true);
        },
        child: Scaffold(
          body: Stack(
            children: [
              _remoteVideo(user),
              StreamBuilder<dynamic>(
                  stream: FirebaseFirestore.instance
                      .collection('livestream')
                      .doc(widget.channelId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    LiveStream post = LiveStream.fromMap(snapshot.data.data());
                    return Positioned(
                      top: 10,
                      left: 8,
                      child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  FontAwesomeIcons.eye,
                                  color: Color(0xff8C8AFA),
                                  size: 16,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  '${post.viewers} watching',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    );
                  }),
              if ("${user!.uid}${user!.displayName}" == widget.channelId)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  height: 70,
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                FontAwesomeIcons.cameraRotate,
                                color: Color(0xff8C8AFA),
                              ),
                              tooltip: 'Switch Camera',
                              onPressed: _switchCamera,
                            ),
                            IconButton(
                              icon: isCameraOn
                                  ? const Icon(
                                      FontAwesomeIcons.video,
                                      color: Colors.white,
                                    )
                                  : const Icon(
                                      FontAwesomeIcons.videoSlash,
                                      color: Color(0xff8C8AFA),
                                    ),
                              tooltip: 'Switch Camera',
                              onPressed: _onToggleCamera,
                            ),
                            IconButton(
                              icon: isMuted
                                  ? const Icon(
                                      FontAwesomeIcons.microphoneSlash,
                                      color: Color(0xff8C8AFA),
                                    )
                                  : const Icon(
                                      FontAwesomeIcons.microphone,
                                      color: Colors.white,
                                    ),
                              tooltip: 'Switch Camera',
                              onPressed: _onToggleMute,
                            ),
                            ElevatedButton(
                              style: const ButtonStyle(
                                backgroundColor:
                                    MaterialStatePropertyAll<Color>(Colors.red),
                              ),
                              onPressed: () async {
                                await _leaveChannel();
                              },
                              child: const Text("End Live"),
                            ),
                          ],
                        ),
                      )),
                ),
              if ("${user!.uid}${user!.displayName}" != widget.channelId)
                Positioned(
                  top: 10,
                  right: 8,
                  child: ElevatedButton(
                    style: const ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll<Color>(Colors.red),
                    ),
                    onPressed: () async {
                      await _leaveChannel();
                    },
                    child: const Text("Leave"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  _remoteVideo(user) {
    if (isAgoraInitialised) {
      return SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: "${user.uid}${user.displayName}" == widget.channelId
            ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
            : remoteUid.isNotEmpty
                ? kIsWeb
                    ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(uid: remoteUid[0]),
                          useFlutterTexture: true,
                          connection:
                              RtcConnection(channelId: widget.channelId),
                        ),
                      )
                    : AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(uid: remoteUid[0]),
                          useAndroidSurfaceView: true,
                          connection:
                              RtcConnection(channelId: widget.channelId),
                        ),
                      )
                : Container(),
      );
    } else {
      return const LoadingIndicator();
    }
  }
}

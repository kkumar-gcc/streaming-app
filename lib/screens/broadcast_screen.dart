import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ombre/resources/firestore_methods.dart';
import 'package:ombre/screens/welcome_screen.dart';
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
  bool _localUserJoined = false;
  bool switchCamera = true;
  bool isMuted = false;
  @override
  void initState() {
    super.initState();
    initAgora();
  }

  final user = FirebaseAuth.instance.currentUser;
  String baseUrl = "http://localhost:8080";
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
          _localUserJoined = true;
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
    // if(defaultTargetPlatform==TargetPlatform.android){
    //   await []
    // }
    await getToken();
    await _engine.joinChannelWithUserAccount(
      token: token!,
      channelId: 'testing123',
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

  _leaveChannel() async {
    await _engine.leaveChannel();
    if ('${user!.uid}${user!.displayName}' == widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updateViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, WelcomeScreen.routeName);
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
              Center(
                child:
                    ('${user!.uid}${user!.displayName}' == widget.channelId) &&
                            _localUserJoined
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const CircularProgressIndicator(),
              ),
              Center(
                child: _remoteVideo(user),
              ),
              Center(
                  child: Column(
                children: [
                  if ("${user!.uid}${user!.displayName}" == widget.channelId)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _switchCamera,
                          child: const Text('switch camera'),
                        ),
                        InkWell(
                          onTap: _onToggleMute,
                          child: Text(isMuted ? 'Un-mute' : 'Mute'),
                        ),
                      ],
                    )
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  _remoteVideo(user) {
    if (remoteUid.isNotEmpty) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: remoteUid[0]),
          connection: const RtcConnection(channelId: "testing123"),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}

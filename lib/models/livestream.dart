class LiveStream {
  final String title;
  final String image;
  final String uid;
  final String name;
  final startedAt;
  final int viewers;
  final String channelId;

  LiveStream({
    required this.title,
    required this.image,
    required this.uid,
    required this.name,
    required this.startedAt,
    required this.viewers,
    required this.channelId,
  });
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
      'uid': uid,
      'name': name,
      'viewers': viewers,
      'channelId': channelId,
      'startedAt': startedAt,
    };
  }

  factory LiveStream.fromMap(Map<String, dynamic> map) {
    return LiveStream(
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      startedAt: map['startedAt'],
      viewers: map['viewers'] ?? 0,
      channelId: map['channelId'] ?? '',
    );
  }
}

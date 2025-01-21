import 'package:cloud_firestore/cloud_firestore.dart';

class Likes {
  final String likeid;
  final String postid;
  final String postuserid;
  final String likeuserid;
  final DateTime timestamp;

  Likes({
    required this.likeid,
    required this.postid,
    required this.postuserid,
    required this.likeuserid,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'likeid': likeid,
      'postid': postid,
      'postuserid': postuserid,
      'likeuserid': likeuserid,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Likes.fromJson(Map<String, dynamic> json) {
    return Likes(
      likeid: json['likeid'] as String,
      postid: json['postid'] as String,
      postuserid: json['postuserid'] as String,
      likeuserid: json['likeuserid'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String recieverID;
  final String message;
  final Timestamp timestamp;
  final String senderemail;
  final String ChatRoomID;
  final String type;

  Message(
      {required this.senderID,
      required this.recieverID,
      required this.message,
      required this.timestamp,
      required this.senderemail,
      required this.ChatRoomID,
      required this.type});

  Map<String, dynamic> toJson() {
    return {
      'senderID': senderID,
      'recieverID': recieverID,
      'message': message,
      'timestamp': timestamp,
      'senderemail': senderemail,
      'ChatRoomID': ChatRoomID,
      'type': type
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        senderID: json['senderID'],
        recieverID: json['recieverID'],
        message: json['message'],
        timestamp: json['timestamp'],
        senderemail: json['senderName'],
        ChatRoomID: json['ChatRoomID'],
        type: json['type']);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ChatRepo {
  Future<void> sendMessage(String receiverID, String message);
  Stream<QuerySnapshot> getMessages(String currentID, String recieverID);
  Future<void> saveFCMToken(String token);
  Future<void> deletemessage(String chatroomID, String messageID);
  Future<String> getFCMToken(String userID);
  Future<List<String>> getChatUsers();
  Future<void> sendImageMessage(String receiverID, String imageUrl);
}

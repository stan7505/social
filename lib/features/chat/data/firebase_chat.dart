import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social/features/chat/domain/repo/Chat_repo.dart';
import 'package:social/features/home/message_bubble/data/MessagebubbleService.dart';
import '../domain/entities/message.dart';
import 'notification_service.dart';

class FirebaseChat implements ChatRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<QuerySnapshot> getMessages(String currentID, String recieverID) {
    List<String> ids = [currentID, recieverID];
    ids.sort();
    String chatroomID = ids.join('_');

    return _firestore
        .collection('chats')
        .doc(chatroomID)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  @override
  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatroomID = ids.join('_');

    Message newMessage = Message(
        senderID: currentUserID,
        recieverID: receiverID,
        message: message,
        timestamp: timestamp,
        senderemail: currentUserEmail,
        ChatRoomID: chatroomID,
        type: 'chat');

    await _firestore
        .collection('chats')
        .doc(chatroomID)
        .collection('messages')
        .add(newMessage.toJson());

    await _firestore.collection('chatRooms').doc(currentUserID).set({
      'chatRooms': FieldValue.arrayUnion([receiverID])
    }, SetOptions(merge: true));

    await _firestore.collection('chatRooms').doc(receiverID).set({
      'chatRooms': FieldValue.arrayUnion([currentUserID])
    }, SetOptions(merge: true));

    MessageBubbleService().storeStreamDateTime(receiverID);
    DocumentSnapshot receiverSnapshot =
        await _firestore.collection('users').doc(receiverID).get();
    String? fcmToken = receiverSnapshot.get('fcmToken');

    if (fcmToken != null) {
      await PushNotificationService().sendPushNotification(
        fcmToken,
        currentUserEmail,
        message,
        chatroomID,
        'chat',
      );
    }
  }

  @override
  Future<void> saveFCMToken(String token) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final String currentUserID = currentUser.uid;
      await _firestore.collection('users').doc(currentUserID).update({
        'fcmToken': token,
      });
    }
  }

  @override
  Future<void> deletemessage(String chatroomID, String messageID) async {
    await _firestore
        .collection('chats')
        .doc(chatroomID)
        .collection('messages')
        .doc(messageID)
        .delete();
  }

  @override
  Future<String> getFCMToken(String userID) async {
    final DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userID).get();
    return userDoc.get('fcmToken');
  }

  @override
  Future<List<String>> getChatUsers() async {
    final String currentUserID = _auth.currentUser!.uid;
    DocumentSnapshot chatRoomsSnapshot =
        await _firestore.collection('chatRooms').doc(currentUserID).get();
    if (chatRoomsSnapshot.exists) {
      List<String> chatUsers =
          List<String>.from(chatRoomsSnapshot.get('chatRooms'));
      return chatUsers;
    } else {
      return [];
    }
  }

  @override
  Future<void> sendImageMessage(String receiverID, String imageUrl) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    List<String> ids = [currentUserID, receiverID];
    ids.sort();
    String chatroomID = ids.join('_');

    Message newMessage = Message(
        senderID: currentUserID,
        recieverID: receiverID,
        message: imageUrl,
        timestamp: timestamp,
        senderemail: currentUserEmail,
        ChatRoomID: chatroomID,
        type: 'image');

    await _firestore
        .collection('chats')
        .doc(chatroomID)
        .collection('messages')
        .add(newMessage.toJson());
    await _firestore.collection('chatRooms').doc(currentUserID).set({
      'chatRooms': FieldValue.arrayUnion([receiverID])
    }, SetOptions(merge: true));

    await _firestore.collection('chatRooms').doc(receiverID).set({
      'chatRooms': FieldValue.arrayUnion([currentUserID])
    }, SetOptions(merge: true));

    MessageBubbleService().storeStreamDateTime(receiverID);
    DocumentSnapshot receiverSnapshot =
    await _firestore.collection('users').doc(receiverID).get();
    String? fcmToken = receiverSnapshot.get('fcmToken');

    if (fcmToken != null) {
      await PushNotificationService().sendPushNotification(
        fcmToken,
        currentUserEmail,
        'sent an image',
        chatroomID,
        'image',
      );
    }
  }
}

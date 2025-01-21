import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBubbleService {
  final CollectionReference notificationCollection =
      FirebaseFirestore.instance.collection('messagebubble');

  Stream<List<DocumentSnapshot>> getNotificationsStream(String userId) {
    return notificationCollection
        .doc(userId)
        .collection('StreamDateTime')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<void> storeStreamDateTime(String userId) async {
    await notificationCollection
        .doc(userId)
        .collection('StreamDateTime')
        .add({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> storeNotificationOpenedDateTime(String userId) async {
    await notificationCollection
        .doc(userId)
        .collection('NotificationOpenedDatetime')
        .add({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<DateTime?> getLastStreamDateTime(String userId) async {
    final snapshot = await notificationCollection
        .doc(userId)
        .collection('StreamDateTime')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return (snapshot.docs.first.data()['timestamp'] as Timestamp).toDate();
    }
    return null;
  }

  Future<DateTime?> getLastNotificationOpenedDateTime(String userId) async {
    final snapshot = await notificationCollection
        .doc(userId)
        .collection('NotificationOpenedDatetime')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return (snapshot.docs.first.data()['timestamp'] as Timestamp).toDate();
    }
    return null;
  }
}

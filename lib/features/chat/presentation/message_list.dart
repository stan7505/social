import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:social/features/chat/data/firebase_chat.dart';
import 'package:social/features/home/presentation/main_page.dart';

import '../../In App Notifications/presentation/cubits/notification_cubits.dart';
import '../../home/message_bubble/domain/cubits/message_bubble_cubits.dart';
import 'chatpage.dart';

class MessagePage extends StatefulWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MessagePage({super.key});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  Map<String, DateTime> messageOpenedTimes = {};
  late MessageBubbleCubit messagecubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    messagecubit = context.read<MessageBubbleCubit>();
  }

  Future<bool> _allMessagesRead() async {
    final chatUsers = await FirebaseChat().getChatUsers();
    for (final receiverID in chatUsers) {
      final ids = [widget._auth.currentUser!.uid, receiverID]..sort();
      final chatroomID = ids.join('_');

      final result = await widget._firestore
          .collection('chats')
          .doc(chatroomID)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final lastMessage = result.docs.first;
        if (isNewMessage(lastMessage['timestamp'], chatroomID)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadMessageOpenedTimes();
  }

  @override
  void dispose() {
    context.read<MessageBubbleCubit>();
    context.read<NotificationCubit>();
    super.dispose();
  }

  Future<void> _loadMessageOpenedTimes() async {
    String userId = widget._auth.currentUser!.uid;
    DocumentSnapshot snapshot = await widget._firestore
        .collection('messageOpenedTimes')
        .doc(userId)
        .get();
    if (snapshot.exists) {
      setState(() {
        messageOpenedTimes = Map<String, DateTime>.from((snapshot.data()
                as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, (value as Timestamp).toDate())));
      });
    }
  }

  Future<void> _saveMessageOpenedTime(String chatroomID) async {
    String userId = widget._auth.currentUser!.uid;
    DateTime now = DateTime.now();
    setState(() {
      messageOpenedTimes[chatroomID] = now;
    });
    await widget._firestore.collection('messageOpenedTimes').doc(userId).set({
      chatroomID: now,
    }, SetOptions(merge: true));
  }

  String formatDateTime(Timestamp timestamp) {
    DateTime messageDate = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageDate);

    if (difference.inDays == 0) {
      // Display time if the message is from today in 12-hour format with AM/PM
      return DateFormat('hh:mm a').format(messageDate);
    } else if (difference.inDays == 1) {
      // Display 'Yesterday' if the message is from yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Display the day of the week if the message is within the last week
      return DateFormat('EEEE').format(messageDate);
    } else {
      // Display the date if the message is older than a week
      return DateFormat('dd/MM/yyyy').format(messageDate);
    }
  }

  bool isNewMessage(Timestamp messageTimestamp, String chatroomID) {
    if (!messageOpenedTimes.containsKey(chatroomID)) {
      return true;
    }
    DateTime messageOpenedTime = messageOpenedTimes[chatroomID]!;
    DateTime messageTime = messageTimestamp.toDate();
    return messageTime.isAfter(messageOpenedTime);
  }

  String getProfileImageUrl(DocumentSnapshot userSnapshot) {
    final data = userSnapshot.data() as Map<String, dynamic>;
    if (data.containsKey('profileImageUrl')) {
      return data['profileImageUrl'];
    } else {
      return 'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const MainPage()));
        _allMessagesRead().then((allRead) {
          if (allRead) {
            messagecubit.markNotificationsAsRead(widget._auth.currentUser!.uid);
          }
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: FutureBuilder<List<String>>(
          future: FirebaseChat().getChatUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No conversations found.'));
            } else {
              List<String> chatUsers = snapshot.data!;
              return ListView.builder(
                itemCount: chatUsers.length,
                itemBuilder: (context, index) {
                  String recieverID = chatUsers[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: widget._firestore
                        .collection('users')
                        .doc(recieverID)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          title: Text('Loading...'),
                        );
                      } else if (userSnapshot.hasError) {
                        return ListTile(
                          title: Text('Error: ${userSnapshot.error}'),
                        );
                      } else if (!userSnapshot.hasData ||
                          !userSnapshot.data!.exists) {
                        return const ListTile(
                          title: Text('User not found'),
                        );
                      } else {
                        String recievername = userSnapshot.data!.get('name');
                        String recieverEmail = userSnapshot.data!.get('email');
                        List<String> ids = [
                          widget._auth.currentUser!.uid,
                          recieverID
                        ];
                        ids.sort();
                        String chatroomID = ids.join('_');
                        return StreamBuilder<QuerySnapshot>(
                          stream: widget._firestore
                              .collection('chats')
                              .doc(chatroomID)
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots(),
                          builder: (context, messageSnapshot) {
                            if (messageSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return ListTile(
                                title: Text(recievername),
                                subtitle: const Text('Loading...'),
                              );
                            } else if (messageSnapshot.hasError) {
                              return ListTile(
                                title: Text(recievername),
                                subtitle:
                                    Text('Error: ${messageSnapshot.error}'),
                              );
                            } else if (!messageSnapshot.hasData ||
                                messageSnapshot.data!.docs.isEmpty) {
                              final image = getProfileImageUrl(userSnapshot.data!);
                              return ListTile(
                                leading: CircleAvatar(
                                  child: CachedNetworkImage(
                                    imageUrl: image,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                                title: Text(recievername),
                                subtitle: const Text('No messages yet'),
                                onTap: () {
                                  _saveMessageOpenedTime(chatroomID);
                                  _allMessagesRead().then((allRead) {
                                    if (allRead) {
                                      messagecubit.markNotificationsAsRead(
                                          widget._auth.currentUser!.uid);
                                    }
                                  });
                                  setState(() {});
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Chatpage(
                                        ChatRoomID: chatroomID,
                                        recieveremail: recieverEmail,
                                        recieverID: recieverID,

                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              var lastMessage = messageSnapshot.data!.docs.first;
                              String messageContent = lastMessage['type'] == 'chat' ? lastMessage['message'] : 'sent an image';
                              String formattedTime =
                                  formatDateTime(lastMessage['timestamp']);
                              bool newMessage = isNewMessage(
                                  lastMessage['timestamp'], chatroomID);
                              bool isFromOtherUser = lastMessage['senderID'] !=
                                  widget._auth.currentUser!.uid;
                              final image = getProfileImageUrl(userSnapshot.data!);
                              return ListTile(
                                leading: CachedNetworkImage(
                                  imageUrl: image,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  imageBuilder: (context, imageProvider) =>
                                      CircleAvatar(
                                    backgroundImage: imageProvider,
                                  ),
                                ),
                                title: Text(recievername),
                                subtitle: Text(messageContent.length > 20
                                    ? messageContent.substring(0, 20) + '...'
                                    : messageContent),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (newMessage && isFromOtherUser)
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.circle,
                                          color: Colors.blue,
                                          size: 10,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  _allMessagesRead().then((allRead) {
                                    if (allRead) {
                                      messagecubit.markNotificationsAsRead(
                                          widget._auth.currentUser!.uid);
                                    }
                                  });
                                  setState(() {});
                                  _saveMessageOpenedTime(chatroomID);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Chatpage(
                                        ChatRoomID: chatroomID,
                                        recieveremail: recieverEmail,
                                        recieverID: recieverID,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        );
                      }
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

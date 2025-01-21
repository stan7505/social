import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:social/features/chat/presentation/message_list.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import '../../profile/presentation/cubits/profile_cubit.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../storage/data/firebase_storage_repo.dart';
import '../data/firebase_chat.dart';

class Chatpage extends StatefulWidget {
  final String recieveremail;
  final String recieverID;
  var ChatRoomID;

  Chatpage(
      {super.key,
        required this.recieveremail,
        required this.recieverID,
        this.ChatRoomID});

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> with WidgetsBindingObserver {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FocusNode messageFocusNode = FocusNode();
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  PlatformFile? imagePickedfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    messagehandler();
    WidgetsBinding.instance.addObserver(this);
    messageFocusNode.addListener(() {
      if (messageFocusNode.hasFocus) {
        scrollDown();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollDown());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    messageFocusNode.dispose();
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    scrollDown();
  }

  void messagehandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      final recieveremail = notification?.title;
      if (notification != null && notification.title != recieveremail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
          ),
        );
      }
    });
  }

  void scrollDown() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() async {
    if (messageController.text.isNotEmpty) {
      String messageText = messageController.text;
      messageController.clear();
      try {
        await FirebaseChat().sendMessage(
          widget.recieverID,
          messageText,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  Future pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        imagePickedfile = result.files.first;
      });
      if (imagePickedfile != null) {
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            bool _isLoading = false;
            return
              StatefulBuilder(
                builder: (context, setState) {
                  return
                    _isLoading
                        ? Center(child: Container(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator()))
                        :AlertDialog(
                      title: const Text('Confirm Image'),
                      content: const Text('Do you want to send this image?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              String imageUrl = await FirebaseStorageRepo().uploadImageChat(imagePickedfile!);
                              await FirebaseChat().sendImageMessage(widget.recieverID, imageUrl);
                              Navigator.pop(context);
                            } catch (e) {
                              // Handle error
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                          child:  const Text('Confirm'),
                        ),
                      ],
                    );
                },
              );
          },
        );
      }
    }
  }

  Widget _buildmessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isSentByCurrentUser = data['senderID'] == FirebaseAuth.instance.currentUser!.uid;
    String formattedTime = DateFormat('hh:mm a').format(data['timestamp'].toDate());
    Widget messageContent;
    if (data['type'] == 'image') {
      messageContent = Container(
        margin: const EdgeInsets.only(top: 15, left: 10, right: 10),
        child: Row(
          mainAxisAlignment: isSentByCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: isSentByCurrentUser ? Colors.brown : Colors.white,
                    width: 2),
                color: isSentByCurrentUser ? const Color(0xFFFAF0E6) : Colors.pink.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: isSentByCurrentUser ? const Radius.circular(15) : const Radius.circular(0),
                  topRight: const Radius.circular(15),
                  bottomLeft: isSentByCurrentUser ? const Radius.circular(15) : const Radius.circular(15),
                  bottomRight: isSentByCurrentUser ? const Radius.circular(0) : const Radius.circular(15),
                ),
              ),
              child: Column(
                crossAxisAlignment: isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: data['message'],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    imageBuilder: (context, imageProvider) => Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover
                        ),
                      ),
                    ),
                  ),
                  data['timestamp'] != null
                      ? Text(
                    formattedTime,
                    style: isSentByCurrentUser
                        ? const TextStyle(color: Colors.black, fontSize: 12)
                        : const TextStyle(color: Colors.white, fontSize: 12),
                  )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      messageContent = Container(
        margin: const EdgeInsets.only(top: 15, left: 10, right: 10),
        child: Row(
          mainAxisAlignment: isSentByCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: isSentByCurrentUser ? Colors.brown : Colors.white,
                      width: 2),
                  color: isSentByCurrentUser ? const Color(0xFFFAF0E6) : Colors.pink.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: isSentByCurrentUser ? const Radius.circular(15) : const Radius.circular(0),
                    topRight: const Radius.circular(15),
                    bottomLeft: isSentByCurrentUser ? const Radius.circular(15) : const Radius.circular(15),
                    bottomRight: isSentByCurrentUser ? const Radius.circular(0) : const Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'],
                      style: isSentByCurrentUser
                          ? const TextStyle(color: Colors.black, fontSize: 16)
                          : const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    data['timestamp'] != null
                        ? Text(
                      formattedTime,
                      style: isSentByCurrentUser
                          ? const TextStyle(color: Colors.black, fontSize: 12)
                          : const TextStyle(color: Colors.white, fontSize: 12),
                    )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return isSentByCurrentUser
        ? Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.2,
        motion: const ScrollMotion(),
        children: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              FirebaseChat().deletemessage(widget.ChatRoomID, doc.id);
            },
          ),
        ],
      ),
      child: messageContent,
    )
        : messageContent;
  }

  Widget _buildMessageList() {
    String senderID = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder(
      stream: FirebaseChat().getMessages(senderID, widget.recieverID),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollDown());

        return ListView.builder(
          controller: _scrollController,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildmessageItem(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  Future<void> _saveMessageOpenedTime(String chatroomID) async {
    String userId = _auth.currentUser!.uid;
    DateTime now = DateTime.now();
    await _firestore.collection('messageOpenedTimes').doc(userId).set({
      chatroomID: now,
    }, SetOptions(merge: true));
  }

  Widget _builduserinput() {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: pickImage,
          ),
          Expanded(
            child: TextField(
              style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
              focusNode: messageFocusNode,
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Enter your message',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              onTap: () {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => scrollDown());
              },
            ),
          ),
          IconButton(
            onPressed: () {
              _saveMessageOpenedTime(widget.ChatRoomID);
              sendMessage();
            },
            icon: Icon(
              Icons.send_outlined,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          )
        ],
      ),
    );
  }

  String getProfileImageUrl(ProfileUser? user) {
    if (user != null && user.profileImageUrl != null) {
      return user.profileImageUrl;
    } else {
      return 'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WillPopScope(
          onWillPop: () async {
            _saveMessageOpenedTime(widget.ChatRoomID);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => MessagePage()));
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _saveMessageOpenedTime(widget.ChatRoomID);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MessagePage()));
                  },
                ),
                centerTitle: true,
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder<ProfileUser?>(
                    future:  context.read<ProfileCubit>().getUserProfile(widget.recieverID),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return  Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                        uid: widget.recieverID
                                    ),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                  backgroundImage: NetworkImage(getProfileImageUrl(snapshot.data))
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(snapshot.data!.name),
                          ],
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.tertiary),
            body: Column(
              children: [
                Expanded(
                  child: _buildMessageList(),
                ),
                _builduserinput(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social/features/In%20App%20Notifications/presentation/cubits/notification_cubits.dart';
import 'package:social/features/auth/data/firebase_auth_repo.dart';
import 'package:social/features/auth/presentation/cubits/auth_state.dart';
import 'package:social/features/home/presentation/main_page.dart';
import 'package:social/features/posts/data/firebase_post_repo.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/themes/cubits/theme_cubit.dart';
import 'features/In App Notifications/Data/firebase_inappnotification.dart';
import 'features/In App Notifications/presentation/pages/inapp_notification.dart';
import 'features/auth/presentation/cubits/auth_cubit.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/chat/presentation/chatpage.dart';
import 'features/home/message_bubble/data/MessagebubbleService.dart';
import 'features/home/message_bubble/domain/cubits/message_bubble_cubits.dart';
import 'features/posts/presentation/cubits/post_cubit.dart';
import 'features/profile/data/firebase_profile_repo.dart';
import 'features/search/data/firebase_search_repo.dart';
import 'features/search/presentation/Cubits/search_cubit.dart';
import 'features/storage/data/firebase_storage_repo.dart';
import 'main.dart';

class MyApp extends StatefulWidget {
  final RemoteMessage? initialMessage;

  const MyApp({super.key, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final authrepo = FirebaseAuthRepo();
  final profileRepo = FirebaseProfileRepo();
  final storagerepo = FirebaseStorageRepo();
  final postrepo = FirebasePostRepo();
  final searchrepo = FirebaseSearchRepo();
  String chatroomID = '';
  RemoteMessage? _pendingMessage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    context.read<ThemeCubit>().setThemeBasedOnSystemBrightness(brightness);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pendingMessage = widget.initialMessage;
    _clearAllNotifications();
    if (_pendingMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageClick(_pendingMessage!);
        _pendingMessage = null; // Reset after handling
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageClick(message);
    });
  }

  void _clearAllNotifications() {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void _handleMessageClick(RemoteMessage message) {
    final String? type = message.data['type'];
    if (type == 'like' || type == 'comment' || type == 'follow') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const InappNotification(),
        ),
      );
    } else if (type == 'chat' &&
        message.data['senderEmail'] != null &&
        message.data['senderID'] != null) {
      print(message.data);
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => Chatpage(
            recieveremail: message.data['senderEmail']!,
            recieverID: message.data['senderID']!,
            ChatRoomID: message.data['ChatRoomID']!,
          ),
        ),
      );
    }
    else if(type == 'image' && message.data['senderEmail'] != null &&
    message.data['senderID'] != null){
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => Chatpage(
            recieveremail: message.data['senderEmail']!,
            recieverID: message.data['senderID']!,
            ChatRoomID: message.data['ChatRoomID']!,
          ),
        ),
      );
    }
    else {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const MainPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(

      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(authRepo: authrepo)..checkauth(),
        ),
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(
            firebaseProfileRepo: profileRepo,
            storageRepo: storagerepo,
            postRepo: postrepo,
          ),
        ),
        BlocProvider<PostCubit>(
          create: (_) => PostCubit(
            postRepo: postrepo,
            storageRepo: storagerepo,
            profilerepo: profileRepo,
          ),
        ),
        BlocProvider<SearchCubit>(
          create: (_) => SearchCubit(searchrepo),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit()
            ..setThemeBasedOnSystemBrightness(
              WidgetsBinding.instance.window.platformBrightness,
            ),
        ),
        BlocProvider<NotificationCubit>(
          create: (_) =>
              NotificationCubit(notificationService: NotificationService())
                ..checkForNewNotifications(_auth.currentUser!.uid)
                ..listenForNotifications(_auth.currentUser!.uid),
        ),
        BlocProvider<MessageBubbleCubit>(
          create: (_) => MessageBubbleCubit(
            messageBubbleService: MessageBubbleService(),
          )
            ..checkForNewNotifications(_auth.currentUser!.uid)
            ..listenForNotifications(_auth.currentUser!.uid),
        ),
      ],

      child: BlocBuilder<ThemeCubit, ThemeData>(

        builder: (context, theme) {
          return MaterialApp(
            navigatorKey: navigatorKey, // Ensure we set the same navigatorKey
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: BlocConsumer<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is UnAuthenticated) {
                  return const AuthPage();
                }
                if (authState is Authenticated) {
                  return const MainPage();
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

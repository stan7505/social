import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'features/chat/data/notification_service.dart';
import 'features/config/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // No need to call _handleMessageClick here
}

void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await PushNotificationService().initialize();
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Handle the initial message and then clear it
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => MyApp(initialMessage: initialMessage),
      ),
    );
    initialMessage = null; // Clear the initial message
  } else {
    runApp(MyApp(initialMessage: initialMessage));
  }
}

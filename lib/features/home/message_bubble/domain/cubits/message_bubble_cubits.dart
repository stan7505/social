import 'package:bloc/bloc.dart';
import 'package:social/features/home/message_bubble/data/MessagebubbleService.dart';

import '../states/message_bubble_states.dart';

class MessageBubbleCubit extends Cubit<MessageBubbleStates> {
  final MessageBubbleService messageBubbleService;

  MessageBubbleCubit({required this.messageBubbleService})
      : super(MessageBubbleInitial());

  void listenForNotifications(String userId) {
    messageBubbleService.getNotificationsStream(userId).listen((notifications) {
      if (notifications.isNotEmpty) {
        emit(const MessageBubbleLoaded(hasNewNotifications: true));
      } else {
        emit(const MessageBubbleLoaded(hasNewNotifications: false));
      }
    });
  }

  Future<void> checkForNewNotifications(String userId) async {
    try {
      emit(MessageBubbleLoading());
      final lastStreamDateTime =
          await messageBubbleService.getLastStreamDateTime(userId);
      final lastNotificationOpenedDateTime =
          await messageBubbleService.getLastNotificationOpenedDateTime(userId);

      if (lastStreamDateTime != null &&
          (lastNotificationOpenedDateTime == null ||
              lastStreamDateTime.isAfter(lastNotificationOpenedDateTime))) {
        emit(const MessageBubbleLoaded(hasNewNotifications: true));
      } else {
        emit(const MessageBubbleLoaded(hasNewNotifications: false));
      }
    } catch (e) {
      emit(const MessageBubbleError(message: 'Failed to check notifications'));
    }
  }

  Future<void> markNotificationsAsRead(String userId) async {
    try {
      await messageBubbleService.storeNotificationOpenedDateTime(userId);
      emit(const MessageBubbleLoaded(hasNewNotifications: false));
    } catch (e) {
      emit(const MessageBubbleError(
          message: 'Failed to mark notifications as read'));
    }
  }
}

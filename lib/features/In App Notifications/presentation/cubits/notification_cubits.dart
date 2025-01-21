import 'package:bloc/bloc.dart';
import '../../Data/firebase_inappnotification.dart';
import '../states/inappnotific_states.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationService notificationService;

  NotificationCubit({required this.notificationService})
      : super(NotificationInitial());

  void listenForNotifications(String userId) {
    notificationService.getNotificationsStream(userId).listen((notifications) {
      if (notifications.isNotEmpty) {
        emit(const NotificationLoaded(hasNewNotificationss: true));
      } else {
        emit(const NotificationLoaded(hasNewNotificationss: false));
      }
    });
  }

  Future<void> checkForNewNotifications(String userId) async {
    try {
      emit(NotificationLoading());
      final lastStreamDateTime =
          await notificationService.getLastStreamDateTime(userId);
      final lastNotificationOpenedDateTime =
          await notificationService.getLastNotificationOpenedDateTime(userId);

      if (lastStreamDateTime != null &&
          (lastNotificationOpenedDateTime == null ||
              lastStreamDateTime.isAfter(lastNotificationOpenedDateTime))) {
        emit(const NotificationLoaded(hasNewNotificationss: true));
      } else {
        emit(const NotificationLoaded(hasNewNotificationss: false));
      }
    } catch (e) {
      emit(const NotificationError(message: 'Failed to check notifications'));
    }
  }

  Future<void> markNotificationsAsRead(String userId) async {
    try {
      await notificationService.storeNotificationOpenedDateTime(userId);
      emit(const NotificationLoaded(hasNewNotificationss: false));
    } catch (e) {
      emit(const NotificationError(
          message: 'Failed to mark notifications as read'));
    }
  }
}

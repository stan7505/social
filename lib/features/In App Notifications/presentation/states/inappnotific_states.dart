import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

//no properties to rebuild the state
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final bool hasNewNotificationss;

  const NotificationLoaded({required this.hasNewNotificationss});

  @override
  List<Object> get props => [hasNewNotificationss];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}

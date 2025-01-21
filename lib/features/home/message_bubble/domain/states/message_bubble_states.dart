import 'package:equatable/equatable.dart';

abstract class MessageBubbleStates extends Equatable {
  const MessageBubbleStates();

//no properties to rebuild the state
  @override
  List<Object> get props => [];
}

class MessageBubbleInitial extends MessageBubbleStates {}

class MessageBubbleLoading extends MessageBubbleStates {}

class MessageBubbleLoaded extends MessageBubbleStates {
  final bool hasNewNotifications;

  const MessageBubbleLoaded({required this.hasNewNotifications});

  @override
  List<Object> get props => [hasNewNotifications];
}

class MessageBubbleError extends MessageBubbleStates {
  final String message;

  const MessageBubbleError({required this.message});

  @override
  List<Object> get props => [message];
}

import '../../../profile/domain/entities/profile_user.dart';

abstract class SearchState {}

class SearchInitialState extends SearchState {}

class SearchLoadingState extends SearchState {}

class SearchLoadedState extends SearchState {
  final List<ProfileUser?> users;

  SearchLoadedState({required this.users});
}

class SearchErrorState extends SearchState {
  final String message;

  SearchErrorState({required this.message});
}

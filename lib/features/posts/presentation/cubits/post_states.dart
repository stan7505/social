import '../../domain/entities/post.dart';

abstract class Poststate {}

class PostInitial extends Poststate {}

class PostLoading extends Poststate {}

class PostUploaded extends Poststate {}

class PostLoaded extends Poststate {
  final List<Post> posts;

  PostLoaded({required this.posts});
}

class PostError extends Poststate {
  final String message;

  PostError({required this.message});
}

class PostUploading extends Poststate {}

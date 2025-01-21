import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/data/firebase_auth_repo.dart';
import 'package:social/features/posts/domain/post_repo.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/profile/domain/repo/profile_repo.dart';
import 'package:social/features/storage/domain/repo/storage_repo.dart';

import '../../domain/entities/comment.dart';
import '../../domain/entities/likes.dart';
import '../../domain/entities/post.dart';

class PostCubit extends Cubit<Poststate> {
  final PostRepo postRepo;
  final StorageRepo storageRepo;
  final Profilerepo profilerepo;

  PostCubit(
      {required this.postRepo,
      required this.storageRepo,
      required this.profilerepo})
      : super(PostInitial());

  final FirebaseAuthRepo _firebaseAuthRepo = FirebaseAuthRepo();

  Future<void> createPost(Post post,
      {String? imagePath, Uint8List? imageBytes}) async {
    try {
      String? imageUrl;

      if (imagePath != null) {
        emit(PostUploading());
        imageUrl = await storageRepo.uploadPostoMobile(imagePath, post.id);
      } else if (imageBytes != null) {
        emit(PostUploading());
        imageUrl = await storageRepo.uploadPostoWeb(imageBytes, post.id);
      }

      final newPost = post.copyWith(imageUrl: imageUrl ?? '');
      await postRepo.createPost(newPost);
      emit(PostUploaded());
    } catch (e) {
      emit(PostError(message: 'Error creating post: $e'));
    }
  }

  Future<void> fetchAllPosts() async {
    try {
      emit(PostLoading());
      final posts = await postRepo.fetchAllPosts();
      emit(PostLoaded(posts: posts));
    } catch (e) {
      emit(PostError(message: 'Error fetching posts: $e'));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      emit(PostLoading());
      await postRepo.deletePost(postId);
      await fetchAllPosts();
    } catch (e) {
      emit(PostError(message: 'Error deleting post: $e'));
    }
  }

  Future<List<Post>> fetchPostByUser(String userId) async {
    try {
      emit(PostLoading());
      final posts = await postRepo.fetchPostByUser(userId);
      emit(PostLoaded(posts: posts));
      return posts;
    } catch (e) {
      emit(PostError(message: 'Error fetching user posts: $e'));
      return [];
    }
  }

  Future<Post?> fetchPostById(String postId) async {
    try {
      final post = await postRepo.fetchPostById(postId);
      return post;
    } catch (e) {
      throw Exception('Failed to fetch post $e');
    }
  }

  Future<void> likePost(String postId, Likes likes) async {
    try {
      await postRepo.likePost(postId, likes);
    } catch (e) {
      emit(PostError(message: 'Error liking post: $e'));
    }
  }

  Future<void> addComment(String postId, Comment comment) async {
    try {
      await postRepo.addComment(postId, comment);
    } catch (e) {
      emit(PostError(message: 'Error adding comment: $e'));
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await postRepo.deleteComment(postId, commentId);
    } catch (e) {
      emit(PostError(message: 'Error deleting comment: $e'));
    }
  }

  Stream<List<Likes>> likesStream(String postId) {
    return postRepo.likesStream(postId);
  }

  Stream<List<Comment>> commentsStream(String postId) {
    return postRepo.commentsStream(postId);
  }
}

import 'package:social/features/posts/domain/entities/post.dart';

import 'entities/comment.dart';
import 'entities/likes.dart';

abstract class PostRepo {
  Future<List<Post>> fetchAllPosts();

  Future<void> createPost(Post post);

  Future<void> deletePost(String postId);

  Future<List<Post>> fetchPostByUser(String userId);

  Future<void> likePost(String postId, Likes likes);

  Future<void> addComment(String postId, Comment comment);

  Future<void> deleteComment(String postId, String commentId);

  Future<void> updatePost(Post post);

  Stream<List<Likes>> likesStream(String postId);

  Stream<List<Comment>> commentsStream(String postId);

  Future<Post?> fetchPostById(String postId);
}

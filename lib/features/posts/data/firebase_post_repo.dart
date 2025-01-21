import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/features/posts/domain/entities/likes.dart';
import 'package:social/features/posts/domain/entities/post.dart';
import 'package:social/features/posts/domain/post_repo.dart';
import '../../In App Notifications/Data/firebase_inappnotification.dart';
import '../../chat/data/firebase_chat.dart';
import '../../chat/data/notification_service.dart';
import '../domain/entities/comment.dart';

class FirebasePostRepo implements PostRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference postCollection =
      FirebaseFirestore.instance.collection('posts');

  @override
  Future<void> createPost(Post post) async {
    try {
      await postCollection.doc(post.id).set(post.toJson());
    } catch (e) {
      throw Exception('Failed to create post $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await postCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post $e');
    }
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    try {
      final postSnapshot =
          await postCollection.orderBy('timestamp', descending: true).get();
      final List<Post> allPosts = postSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return allPosts;
    } catch (e) {
      throw Exception('Failed to fetch posts $e');
    }
  }

  @override
  Future<List<Post>> fetchPostByUser(String userId) async {
    try {
      final postSnapshot =
          await postCollection.where('userId', isEqualTo: userId).get();
      final List<Post> userPosts = postSnapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return userPosts;
    } catch (e) {
      throw Exception('Failed to fetch user posts $e');
    }
  }

  @override
  Future<void> likePost(String postId, Likes likes) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        final existingLike = post.likes.firstWhere(
          (like) => like.likeuserid == likes.likeuserid,
          orElse: () => Likes(
              timestamp: DateTime.now(),
              likeid: '',
              postid: '',
              postuserid: '',
              likeuserid: ''), // Provide default values
        );
        if (existingLike.likeuserid.isEmpty) {
          // Add like if it does not exist
          post.likes.add(likes);
          NotificationService().storeStreamDateTime(post.userId);
        } else {
          // Remove like if it exists
          post.likes.removeWhere((like) => like.likeuserid == likes.likeuserid);
        }

        await postCollection.doc(postId).update(
            {'likes': post.likes.map((like) => like.toJson()).toList()});
        if (existingLike.likeuserid.isEmpty) {
          final fcmToken = await FirebaseChat().getFCMToken(post.userId);
          if (fcmToken != null) {
            await PushNotificationService().sendPushNotification(
                fcmToken,
                _auth.currentUser!.email!,
                'Your post was liked!',
                postId,
                'like');
          }
        }
      } else {
        throw Exception('Post does not exist');
      }
    } catch (e) {
      throw Exception('Failed to like post $e');
    }
  }

  @override
  Future<void> addComment(String postId, Comment comment) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        post.comments.add(comment);
        await postCollection.doc(postId).update({
          'comments': post.comments.map((comment) => comment.toJson()).toList()
        });
        NotificationService().storeStreamDateTime(post.userId);
        final fcmToken = await FirebaseChat().getFCMToken(post.userId);
        if (fcmToken != null) {
          await PushNotificationService().sendPushNotification(
              fcmToken,
              _auth.currentUser!.email!,
              'Someone commented on your post!',
              postId,
              'comment');
        }
      } else {
        throw Exception('Post does not exist');
      }
    } catch (e) {
      throw Exception('Failed to add comment $e');
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        final post = Post.fromJson(postDoc.data() as Map<String, dynamic>);
        post.comments.removeWhere((element) => element.id == commentId);
        await postCollection.doc(postId).update({
          'comments': post.comments.map((comment) => comment.toJson()).toList()
        });
      } else {
        throw Exception('Post does not exist');
      }
    } catch (e) {
      throw Exception('Failed to delete comment $e');
    }
  }

  @override
  Future<void> updatePost(Post post) {
    final updatedPost = post.toJson();
    return postCollection.doc(post.id).update(updatedPost);
  }

  @override
  Stream<List<Likes>> likesStream(String userId) {
    return postCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<Likes> likes = [];
      for (var doc in snapshot.docs) {
        final post = Post.fromJson(doc.data() as Map<String, dynamic>);
        likes.addAll(post.likes);
      }
      likes.sort((a, b) => b.timestamp
          .compareTo(a.timestamp)); // Ensure likes are sorted by timestamp
      return likes;
    });
  }

  @override
  Stream<List<Comment>> commentsStream(String userId) {
    return postCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      final List<Comment> comments = [];
      for (var doc in snapshot.docs) {
        final post = Post.fromJson(doc.data() as Map<String, dynamic>);
        comments.addAll(post.comments);
      }
      comments.sort((a, b) => b.timestamp
          .compareTo(a.timestamp)); // Ensure comments are sorted by timestamp
      return comments;
    });
  }

  @override
  Future<Post?> fetchPostById(String postId) async {
    try {
      final postDoc = await postCollection.doc(postId).get();
      if (postDoc.exists) {
        return Post.fromJson(postDoc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch post $e');
    }
  }
}

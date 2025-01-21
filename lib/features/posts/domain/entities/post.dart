import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social/features/posts/domain/entities/comment.dart';
import 'package:social/features/posts/domain/entities/likes.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String imageUrl;
  final DateTime timestamp;
  final List<Likes> likes;
  final List<Comment> comments;
  late final bool private;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.private,
  });

  Post copyWith({String? imageUrl, bool? private}) {
    return Post(
      id: id,
      userId: userId,
      userName: userName,
      text: text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp,
      likes: likes,
      comments: comments,
      private: private ?? this.private,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes.map((like) => like.toJson()).toList(),
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'private': private,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<Comment> comments =
        (json['comments'] as List<dynamic>?)?.map((comment) {
              return Comment.fromJson(comment);
            }).toList() ??
            [];

    final List<Likes> likes = (json['likes'] as List<dynamic>?)?.map((like) {
          return Likes.fromJson(like);
        }).toList() ??
        [];

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      likes: likes,
      comments: comments,
      private: json['private'] ?? false,
    );
  }
}

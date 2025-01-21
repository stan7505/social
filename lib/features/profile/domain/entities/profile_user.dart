import 'package:social/features/auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String bio;
  final String profileImageUrl;
  final List<String> followers;
  final List<String> following;
  // true for private, false for public
  final bool publicorprivate;
  final List<String> followrequests;

  ProfileUser(
      {required super.uid,
      required super.email,
      required super.name,
      required this.bio,
      required this.profileImageUrl,
      required this.followers,
      required this.following,
      required this.publicorprivate,
      required this.followrequests});

  ProfileUser copyWith(
      {String? newBio,
      String? newProfileImageUrl,
      List<String>? newFollowers,
      List<String>? newFollowing,
      bool? newPublicorPrivate,
      List<String>? newFollowrequests}) {

    return ProfileUser(
        uid: uid,
        email: email,
        name: name,
        bio: newBio ?? bio,
        profileImageUrl: newProfileImageUrl ?? profileImageUrl ?? '',
        followers: newFollowers ?? followers,
        following: newFollowing ?? following,
        publicorprivate: newPublicorPrivate ?? publicorprivate,
        followrequests: newFollowrequests ?? followrequests);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'publicorprivate': publicorprivate,
      'followrequests': followrequests
    };
  }

  @override
  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl']?? '',
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
      publicorprivate: json['publicorprivate'] ?? true,
      followrequests: List<String>.from(json['followrequests'] ?? []),
    );
  }
}

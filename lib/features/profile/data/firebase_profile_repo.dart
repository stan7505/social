import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/repo/profile_repo.dart';

import '../../In App Notifications/Data/firebase_inappnotification.dart';
import '../../chat/data/firebase_chat.dart';
import '../../chat/data/notification_service.dart';

class FirebaseProfileRepo implements Profilerepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final firebasefirestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      final userDoc =
          await firebasefirestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final followers = List<String>.from(userData!['followers'] ?? []);
        final following = List<String>.from(userData['following'] ?? []);
        return ProfileUser(
          uid: uid,
          email: userData['email'],
          name: userData['name'],
          bio: userData['bio'] ?? '',
          profileImageUrl: userData['profileImageUrl'].toString() ?? '',
          followers: followers,
          following: following,
          publicorprivate: userData['publicorprivate'] ?? true,
          followrequests: List<String>.from(userData['followrequests'] ?? []),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    try {
      await firebasefirestore
          .collection('users')
          .doc(updatedProfile.uid)
          .update({
        'bio': updatedProfile.bio,
        'profileImageUrl': updatedProfile.profileImageUrl,
        'publicorprivate': updatedProfile.publicorprivate,
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      final currentuserDoc =
          await firebasefirestore.collection('users').doc(currentUserId).get();
      final targetUserDoc =
          await firebasefirestore.collection('users').doc(targetUserId).get();

      if (currentuserDoc.exists && targetUserDoc.exists) {
        final currentuserData = currentuserDoc.data();
        final targetuserData = targetUserDoc.data();

        if (currentuserData != null && targetuserData != null) {
          final List<String> currentuserFollowing =
              List<String>.from(currentuserData['following'] ?? []);
          final List<String> targetUserFollowRequests =
              List<String>.from(targetuserData['followrequests'] ?? []);
          final bool isTargetUserprivate = targetuserData['publicorprivate'] ?? true;

          if (currentuserFollowing.contains(targetUserId)) {
            await firebasefirestore
                .collection('users')
                .doc(currentUserId)
                .update({
              'following': FieldValue.arrayRemove([targetUserId]),
            });
            await firebasefirestore
                .collection('users')
                .doc(targetUserId)
                .update({
              'followers': FieldValue.arrayRemove([currentUserId]),
            });
          } else if (!isTargetUserprivate) {
            await firebasefirestore
                .collection('users')
                .doc(currentUserId)
                .update({
              'following': FieldValue.arrayUnion([targetUserId]),
            });
            await firebasefirestore
                .collection('users')
                .doc(targetUserId)
                .update({
              'followers': FieldValue.arrayUnion([currentUserId]),
            });
            final fcmToken = await FirebaseChat().getFCMToken(targetUserId);
            if (fcmToken != null) {
              await PushNotificationService().sendPushNotification(
                  fcmToken,
                  _auth.currentUser!.email!,
                  'Someone followed you!',
                  targetUserId,
                  'follow');
            }
          } else if (!targetUserFollowRequests.contains(currentUserId)) {
            await firebasefirestore
                .collection('users')
                .doc(targetUserId)
                .update({
              'followrequests': FieldValue.arrayUnion([currentUserId]),
            });
            final fcmToken = await FirebaseChat().getFCMToken(targetUserId);
            if (fcmToken != null) {
              await PushNotificationService().sendPushNotification(
                  fcmToken,
                  _auth.currentUser!.email!,
                  'Someone requested to you!',
                  targetUserId,
                  'follow');
            }
            NotificationService().storeStreamDateTime(targetUserId);
          }
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Stream<List<String>> followRequestsStream(String userId) {
    return firebasefirestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        return List<String>.from(data['followrequests'] ?? []);
      }
      return [];
    });
  }

  @override
  Future<void> acceptFollowRequest(String currentUserId, String requesterId) async {
    try {
      final currentuserDoc =
          await firebasefirestore.collection('users').doc(currentUserId).get();
      final requesterDoc =
          await firebasefirestore.collection('users').doc(requesterId).get();

      if (currentuserDoc.exists && requesterDoc.exists) {
        final currentuserData = currentuserDoc.data();
        final requesterData = requesterDoc.data();

        if (currentuserData != null && requesterData != null) {
          await firebasefirestore
              .collection('users')
              .doc(currentUserId)
              .update({
            'followers': FieldValue.arrayUnion([requesterId]),
            'followrequests': FieldValue.arrayRemove([requesterId]),
          });
          await firebasefirestore.collection('users').doc(requesterId).update({
            'following': FieldValue.arrayUnion([currentUserId]),
          });
          final fcmToken = await FirebaseChat().getFCMToken(requesterId);
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> togglePrivacy(String userId) async {
    try {
      final userDoc =
          await firebasefirestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final currentPrivacy = userData['publicorprivate'] ?? true;
          await firebasefirestore.collection('users').doc(userId).update({
            'publicorprivate': !currentPrivacy,
          });
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> deleteFollowRequest(String currentUserId, String targetUserId) async {
    try {
      await firebasefirestore.collection('users').doc(targetUserId).update({
        'followrequests': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await firebasefirestore.collection('users').doc(currentUserId).update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });
      await firebasefirestore.collection('users').doc(targetUserId).update({
        'followers': FieldValue.arrayRemove([currentUserId]),
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Stream<ProfileUser> userProfileStream(String uid) {
    return firebasefirestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      final userData = snapshot.data();
      final followers = List<String>.from(userData!['followers'] ?? []);
      final following = List<String>.from(userData['following'] ?? []);
      return ProfileUser(
        uid: uid,
        email: userData['email'],
        name: userData['name'],
        bio: userData['bio'] ?? '',
        profileImageUrl: userData['profileImageUrl'].toString() ?? 'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd',
        followers: followers,
        following: following,
        publicorprivate: userData['publicorprivate'] ?? true,
        followrequests: List<String>.from(userData['followrequests'] ?? []),
      );
    });
  }
}

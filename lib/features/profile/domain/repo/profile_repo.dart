import 'package:social/features/profile/domain/entities/profile_user.dart';

abstract class Profilerepo {
  Future<ProfileUser?> fetchUserProfile(String uid);

  Future<void> updateProfile(ProfileUser updatedProfile);

  Future<void> followUser(String currentUserId, String targetUserId);

  Future<void> togglePrivacy(String userId);

  Future<void> acceptFollowRequest(String currentUserId, String targetUserId);

  Stream<List<String>> followRequestsStream(String userId);

  Future<void> deleteFollowRequest(String currentUserId, String targetUserId);

  Future<void> unfollowUser(String currentUserId, String targetUserId);

  Stream<ProfileUser> userProfileStream(String uid);
}

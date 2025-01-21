import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/posts/domain/post_repo.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/domain/repo/profile_repo.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import 'package:social/features/storage/domain/repo/storage_repo.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final Profilerepo firebaseProfileRepo;
  final StorageRepo storageRepo;
  final PostRepo postRepo;

  ProfileCubit({
    required this.firebaseProfileRepo,
    required this.storageRepo,
    required this.postRepo,
  }) : super(ProfileInitial());

  Future<void> fetchUserProfile(String uid) async {
    try {
      final user = await firebaseProfileRepo.fetchUserProfile(uid);
      if (user != null) {
        emit(ProfileLoaded(user: user));
      } else {
        emit(ProfileError(message: 'User not found'));
      }
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<ProfileUser?> getUserProfile(String uid) async {
    print('[ProfileCubit] getUserProfile called with uid: $uid');
    try {
      final user = await firebaseProfileRepo.fetchUserProfile(uid);
      return user;
    } catch (e) {
      print('[ProfileCubit] getUserProfile exception: $e');
      emit(ProfileError(message: e.toString()));
      return null;
    }
  }

  Future<void> updateProfile({required String uid, String? newBio, Uint8List? imageWebBytes, String? imageMobilePath, bool? publicorprivate,}) async {
    emit(ProfileLoading());
    try {
      final currentuser = await firebaseProfileRepo.fetchUserProfile(uid);
      if (currentuser == null) {
        emit(ProfileError(message: 'User not found'));
        return;
      }
      String? imageDownloadUrl;
      if (imageWebBytes != null || imageMobilePath != null) {
        if (imageMobilePath != null) {
          imageDownloadUrl =
              await storageRepo.uploadProfileImageMobile(imageMobilePath, uid);
        } else if (imageWebBytes != null) {
          imageDownloadUrl =
              await storageRepo.uploadProfileImageWeb(imageWebBytes, uid);
        }
        if (imageDownloadUrl == null) {
          emit(ProfileError(message: 'Image upload failed'));
          return;
        }
      }
      final updatedProfile = currentuser.copyWith(
        newBio: newBio ?? currentuser.bio,
        newProfileImageUrl: imageDownloadUrl ?? currentuser.profileImageUrl,
        newPublicorPrivate: publicorprivate ?? currentuser.publicorprivate,
      );
      await firebaseProfileRepo.updateProfile(updatedProfile);
      await fetchUserProfile(uid);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> followUser(String currentUserId, String targetUserId) async {
    try {
      await firebaseProfileRepo.followUser(currentUserId, targetUserId);
      await fetchUserProfile(targetUserId);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> togglePrivacy(String userId) async {
    try {
      final user = await firebaseProfileRepo.fetchUserProfile(userId);
      if (user == null) {
        emit(ProfileError(message: 'User not found'));
        return;
      }
      final newPrivacyStatus = !user.publicorprivate;
      final updatedUser = user.copyWith(newPublicorPrivate: newPrivacyStatus);
      await firebaseProfileRepo.updateProfile(updatedUser);
      final posts = await postRepo.fetchPostByUser(userId);
      for (final post in posts) {
        final updatedPost = post.copyWith(private: newPrivacyStatus);
        await postRepo.updatePost(updatedPost);
      }
      emit(ProfileUpdated());
      await fetchUserProfile(userId);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> acceptFollowRequest(String currentUserId, String targetUserId) async {
    try {
      await firebaseProfileRepo.acceptFollowRequest(
          currentUserId, targetUserId);
      await fetchUserProfile(targetUserId);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Stream<List<String>> followRequestsStream(String userId) {
    return firebaseProfileRepo.followRequestsStream(userId);
  }

  Future<void> deleteFollowRequest(String currentUserId, String targetUserId) async {
    try {
      await firebaseProfileRepo.deleteFollowRequest(
          currentUserId, targetUserId);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    try {
      await firebaseProfileRepo.unfollowUser(currentUserId, targetUserId);
      await fetchUserProfile(targetUserId);
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Stream<ProfileUser> userProfileStream(String uid) {
    return firebaseProfileRepo.userProfileStream(uid);
  }
}

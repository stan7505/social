import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/profile/presentation/components/biobox.dart';
import 'package:social/features/profile/presentation/components/follow_button.dart';
import 'package:social/features/profile/presentation/components/profile_stats.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../chat/presentation/chatpage.dart';
import '../../../posts/presentation/post_page.dart';
import '../../domain/entities/profile_user.dart';
import 'edit_profile_page.dart';
import 'follower_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  AppUser? currentUser;
  bool isOwnPost = false;
  late var postcount = 0;

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().fetchUserProfile(widget.uid);
    getCurrentUser();
    getpostcount();
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
    isOwnPost = widget.uid == currentUser!.uid;
  }

  void getpostcount() {
    final postCubit = context.read<PostCubit>();
    final poststate = postCubit.state;
    if (poststate is PostLoaded) {
      final allPosts = poststate.posts;
      final userPosts =
          allPosts.where((element) => element.userId == widget.uid).toList();
      postcount = userPosts.length;
    }
  }

  void followbuttonPressed() async {
    await context.read<ProfileCubit>().followUser(currentUser!.uid, widget.uid);
    setState(() {});
  }

  void unfollowbuttonPressed() {
    setState(() {});
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Unfollow'),
              content:
                  const Text('Are you sure you want to unfollow this user?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    context
                        .read<ProfileCubit>()
                        .unfollowUser(currentUser!.uid, widget.uid);
                    Navigator.pop(context);
                  },
                  child: const Text('Unfollow'),
                ),
              ],
            ));
  }

  void toggleFollowRequest() async {
    final currentUserId = currentUser!.uid;
    await context
        .read<ProfileCubit>()
        .deleteFollowRequest(currentUser!.uid, widget.uid);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          setState(() {});
        }
      },
      child: StreamBuilder<ProfileUser>(
        stream: context.read<ProfileCubit>().userProfileStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = snapshot.data!;
            ImageProvider backgroundImage;
            if (user.profileImageUrl != null &&
                user.profileImageUrl.isNotEmpty &&
                user.profileImageUrl != 'null') {
              backgroundImage =
                  CachedNetworkImageProvider(user.profileImageUrl);
            } else {
              backgroundImage = const CachedNetworkImageProvider(
                'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd',
              );
            }
            return Scaffold(
              appBar: AppBar(
                actions: [
                  isOwnPost
                      ? IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfilePage(
                                  user: user,
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ],
                centerTitle: true,
                title: Text(
                  user.name,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary),
                ),
              ),
              body: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: backgroundImage,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        user.email,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.inversePrimary),
                      ),
                    ),
                    if (!isOwnPost)
                      StreamBuilder<List<String>>(
                        stream: context
                            .read<ProfileCubit>()
                            .followRequestsStream(widget.uid),
                        builder: (context, snapshot) {
                          List<String> ids = [currentUser!.uid,widget.uid];
                          ids.sort();
                          String chatroomID = ids.join('_');
                          if (snapshot.hasData) {
                            final followRequests = snapshot.data!;
                            if (followRequests.contains(currentUser!.uid)) {
                              return ElevatedButton(
                                onPressed: toggleFollowRequest,
                                child: const Text('Cancel Request'),
                              );
                            } else if (user.followers
                                .contains(currentUser!.uid)) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: unfollowbuttonPressed,
                                    child: Text('Unfollow',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Chatpage(
                                              recieveremail: user.email,
                                              recieverID: user.uid,
                                              ChatRoomID:  chatroomID,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.message)),
                                ],
                              );
                            } else {
                              return FollowButton(
                                onPressed: followbuttonPressed,
                                isFollowing:
                                    user.followers.contains(currentUser!.uid),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      if(user.uid == currentUser!.uid || user.publicorprivate == false)
                      ProfileStats(
                        postscount: postcount,
                        followerscount: user.followers.length,
                        followingcount: user.following.length,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowerPage(
                                followers: user.followers,
                                following: user.following,
                              ),
                            ),
                          );
                        },
                      ),
                    Text(
                      user.publicorprivate ? 'Private' : 'Public',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Bio:',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Biobox(text: user.bio),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Posts:',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ),
                    user.followers.contains(currentUser!.uid) ||
                            user.uid == currentUser!.uid ||
                            !user.publicorprivate == true
                        ? Expanded(
                            child: BlocBuilder<PostCubit, Poststate>(
                              builder: (context, state) {
                                if (state is PostLoading ||
                                    state is PostUploading) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                } else if (state is PostLoaded) {
                                  final allPosts = state.posts
                                      .where((element) =>
                                          element.userId == user.uid)
                                      .toList();
                                  if (allPosts.isEmpty) {
                                    return const Center(
                                        child: Text('No posts yet'));
                                  } else {
                                    return GridView.builder(
                                        itemCount: allPosts.length,
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3),
                                        itemBuilder: (context, index) {
                                          final post = allPosts[index];
                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PostPage(
                                                    uid: user.uid,
                                                    focusPostId: post.id,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.all(5),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                          post.imageUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        });
                                  }
                                } else if (state is PostError) {
                                  return Center(child: Text(state.message));
                                }
                                return const SizedBox();
                              },
                            ),
                          )
                        : const Center(child: Text('This account is private')),
                  ],
                ),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return const Center(
              child: Text('No Profile found'),
            );
          }
        },
      ),
    );
  }
}

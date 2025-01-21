import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/home/presentation/main_page.dart';
import 'package:social/features/posts/domain/entities/likes.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../posts/domain/entities/comment.dart';
import '../../../posts/domain/entities/post.dart';
import '../../../posts/presentation/cubits/post_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../cubits/notification_cubits.dart';

class InappNotification extends StatefulWidget {
  const InappNotification({super.key});

  @override
  State<InappNotification> createState() => _InappNotificationState();
}

class _InappNotificationState extends State<InappNotification> {
  String? currentUserUid;
  late NotificationCubit notificationCubit;
  ProfileUser? user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    notificationCubit = context.read<NotificationCubit>();
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthCubit>().currentUser;
    if (user != null) {
      currentUserUid = user.uid;
      notificationCubit = context.read<NotificationCubit>();
      // Mark that we've fetched new notifications now
      notificationCubit.markNotificationsAsRead(user.uid);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchUserProfile(String uid) async {
    try {
      final user = await context.read<ProfileCubit>().getUserProfile(uid);
      if (user != null) {
        setState(() {
          this.user = user;
        });
      }
    } catch (e) {
      throw Exception('Error fetching user profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const MainPage()));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Notifications'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Follow requests
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
                      child: Text('Follow Requests:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    StreamBuilder<List<String>>(
                      stream: context
                          .read<ProfileCubit>()
                          .followRequestsStream(currentUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final followRequests = snapshot.data!;
                          if (followRequests.isEmpty) {
                            return const Center(
                                child: Text('No follow requests'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: followRequests.length,
                            itemBuilder: (context, index) {
                              final requesterId = followRequests[index];
                              return FutureBuilder<ProfileUser?>(
                                future: context
                                    .read<ProfileCubit>()
                                    .getUserProfile(requesterId),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: ListTile(
                                        title: SizedBox(
                                          width: 10,
                                          child: LinearProgressIndicator(),
                                        ),
                                      ),
                                    );
                                  } else if (userSnapshot.hasData) {
                                    final user = userSnapshot.data!;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                                user.profileImageUrl),
                                      ),
                                      title: Text(user.name),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        // Add this line to constrain the Row's width
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                            onPressed: () {
                                              context
                                                  .read<ProfileCubit>()
                                                  .acceptFollowRequest(
                                                      currentUser.uid,
                                                      requesterId);
                                            },
                                            child: Text('Accept',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary)),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                context
                                                    .read<ProfileCubit>()
                                                    .deleteFollowRequest(
                                                        currentUser.uid,
                                                        requesterId);
                                              },
                                              icon: const Icon(Icons.close)),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return const ListTile(
                                      title: Text('Error loading user'),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ],
                ),
                const Divider(),
                // Likes
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
                      child: Text('Likes:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    StreamBuilder<List<Likes>>(
                      stream: context
                          .read<PostCubit>()
                          .likesStream(currentUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final likes = snapshot.data!;
                          if (likes.isEmpty) {
                            return const Center(child: Text('No likes'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: likes.length,
                            itemBuilder: (context, index) {
                              final likerData = likes[index];
                              final likerId = likerData.likeuserid;
                              final postId = likerData.postid;
                              return FutureBuilder<ProfileUser?>(
                                future: context
                                    .read<ProfileCubit>()
                                    .getUserProfile(likerId),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: ListTile(
                                        title: SizedBox(
                                          width: 10,
                                          child: LinearProgressIndicator(),
                                        ),
                                      ),
                                    );
                                  } else if (userSnapshot.hasData) {
                                    final user = userSnapshot.data!;
                                    return ListTile(
                                      leading: GestureDetector(
                                        onTap: () {
                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            builder: (context) =>
                                                ProfilePage(uid: user.uid),
                                          ));
                                        },
                                        child: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  user.profileImageUrl),
                                        ),
                                      ),
                                      title:
                                          Text('${user.name} liked your post'),
                                      trailing: FutureBuilder<Post?>(
                                        future: context
                                            .read<PostCubit>()
                                            .fetchPostById(postId),
                                        builder: (context, postSnapshot) {
                                          if (postSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 50,
                                              height: 50,
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          } else if (postSnapshot.hasData) {
                                            final post = postSnapshot.data!;
                                            return SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl: post.imageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          } else {
                                            return const SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: Icon(Icons.error),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  } else {
                                    return const ListTile(
                                      title: Text('Error loading user'),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  ],
                ),
                const Divider(),
                // Comments
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
                      child: Text('Comments:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    StreamBuilder<List<Comment>>(
                      stream: context
                          .read<PostCubit>()
                          .commentsStream(currentUser.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final comments = snapshot.data!;
                          if (comments.isEmpty) {
                            return const Center(
                                child: Text('No notifications'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return FutureBuilder<ProfileUser?>(
                                future: context
                                    .read<ProfileCubit>()
                                    .getUserProfile(comment.userId),
                                builder: (context, userSnapshot) {
                                  if (userSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: ListTile(
                                        title: SizedBox(
                                          width: 10,
                                          child: LinearProgressIndicator(),
                                        ),
                                      ),
                                    );
                                  } else if (userSnapshot.hasData) {
                                    final user = userSnapshot.data!;
                                    return FutureBuilder<Post?>(
                                      future: context
                                          .read<PostCubit>()
                                          .fetchPostById(comment.postId),
                                      builder: (context, postSnapshot) {
                                        if (postSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: ListTile(
                                              title: SizedBox(
                                                width: 10,
                                                child:
                                                    LinearProgressIndicator(),
                                              ),
                                            ),
                                          );
                                        } else if (postSnapshot.hasData) {
                                          final post = postSnapshot.data!;
                                          return ListTile(
                                            leading: GestureDetector(
                                              onTap: () {
                                                Navigator.of(context)
                                                    .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfilePage(
                                                          uid: user.uid),
                                                ));
                                              },
                                              child: CircleAvatar(
                                                backgroundImage:
                                                    CachedNetworkImageProvider(
                                                        user.profileImageUrl),
                                              ),
                                            ),
                                            title: Text(
                                                '${user.name} commented: ${comment.text}'),
                                            trailing: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl: post.imageUrl,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const ListTile(
                                            title: Text('Error loading post'),
                                          );
                                        }
                                      },
                                    );
                                  } else {
                                    return const ListTile(
                                      title: Text('Error loading user'),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                        return const Center(
                          child: SizedBox(
                            width: 10,
                            child: LinearProgressIndicator(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

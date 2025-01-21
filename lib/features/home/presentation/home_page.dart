import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/chat/presentation/message_list.dart';
import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../chat/data/notification_service.dart';
import '../../posts/presentation/components/posttile.dart';
import '../../posts/presentation/cubits/post_cubit.dart';
import '../../posts/presentation/cubits/post_states.dart';
import '../../profile/presentation/cubits/profile_cubit.dart';
import '../components/my_drawer.dart';
import '../message_bubble/data/MessagebubbleService.dart';
import '../message_bubble/domain/cubits/message_bubble_cubits.dart';
import '../message_bubble/domain/states/message_bubble_states.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  late final postCubit = context.read<PostCubit>();
  late final String currentUserId;
  var currentUserProfile;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    currentUserId = context.read<AuthCubit>().currentUser!.uid;
    postCubit.fetchAllPosts();
    _fetchCurrentUserProfile();
    PushNotificationService().initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    MessageBubbleService().storeNotificationOpenedDateTime(currentUserId);
    super.dispose();
  }

  Future<void> _fetchCurrentUserProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    currentUserProfile = await profileCubit.getUserProfile(currentUserId);
    setState(() {});
  }

  bool isFollowing(String userId) {
    if (currentUserProfile == null) return false;
    return currentUserProfile.following.contains(userId);
  }

  Future<void> _refreshPosts() async {
    _fetchCurrentUserProfile();
    await postCubit.fetchAllPosts();
  }

  void deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () {
                postCubit.deletePost(postId);
                Navigator.pop(context);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> checkIfUserIsFollowing(String userId) async {
    final profileCubit = context.read<ProfileCubit>();
    final user = await profileCubit.getUserProfile(currentUserId);

    if (user != null) {
      return user.following.contains(userId);
    }
    return false;
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Follow to see More Posts"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MessagePage()),
                  ).then((_) {
                    setState(() {}); // rebuild to update bubble
                  });
                },
                icon: Icon(
                  Icons.message,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              BlocBuilder<MessageBubbleCubit, MessageBubbleStates>(
                builder: (context, state) {
                  if (state is MessageBubbleLoaded &&
                      state.hasNewNotifications) {
                    return Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
        title: const Text('Home'),
      ),
      drawer: const MyDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: Column(
          children: [
            Expanded(
              child:
                  BlocBuilder<PostCubit, Poststate>(builder: (context, state) {
                if (state is PostLoading || state is PostUploading) {
                  return const Center(
                    child: SizedBox(
                      height: 5,
                      width: 200,
                      child: LinearProgressIndicator(),
                    ),
                  );
                } else if (state is PostLoaded) {
                  final allPosts = state.posts;
                  if (allPosts.isEmpty) {
                    return const Center(child: Text('No posts yet'));
                  } else {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: allPosts.length,
                      itemBuilder: (context, index) {
                        final post = allPosts[index];
                        return Posttile(
                          post: post,
                          isFollowing: isFollowing(post.userId),
                          onDelete: () {
                            deletePost(post.id);
                          },
                        );
                      },
                    );
                  }
                } else if (state is PostError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox();
              }),
            ),
          ],
        ),
      ),
    );
  }
}

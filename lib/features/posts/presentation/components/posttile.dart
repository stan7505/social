import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/posts/presentation/components/commentspage.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../profile/domain/entities/profile_user.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/likes.dart';
import '../../domain/entities/post.dart';
import '../cubits/post_cubit.dart';

class Posttile extends StatefulWidget {
  final Post post;
  final void Function()? onDelete;
  bool isFollowing;

  Posttile({
    super.key,
    required this.post,
    required this.onDelete,
    this.isFollowing = false,
  });

  @override
  State<Posttile> createState() => _PosttileState();
}

class _PosttileState extends State<Posttile>
    with SingleTickerProviderStateMixin {
  bool isOwnPost = false;
  AppUser? currentUser;
  ProfileUser? postUser;
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  TextEditingController commentController = TextEditingController();
  bool showSplash = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    fetchPostUser();
    getCurrentUser();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    super.initState();
  }

  Future<void> fetchPostUser() async {
    final fetcheduser = await profileCubit.getUserProfile(widget.post.userId);
    if (!mounted) return;
    if (fetcheduser != null) {
      setState(() {
        postUser = fetcheduser;
      });
    }
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
    isOwnPost = widget.post.userId == currentUser!.uid;
  }

  void togglelike() {
    final isLiked =
        widget.post.likes.any((like) => like.likeuserid == currentUser!.uid);
    final likeId = DateTime.now().millisecondsSinceEpoch.toString();
    final newLike = Likes(
      likeid: likeId,
      postid: widget.post.id,
      postuserid: widget.post.userId,
      likeuserid: currentUser!.uid,
      timestamp: DateTime.now(),
    );

    setState(() {
      showSplash = true;
      _controller.forward(from: 0.0); // Start the animation
      if (isLiked) {
        widget.post.likes
            .removeWhere((like) => like.likeuserid == currentUser!.uid);
      } else {
        widget.post.likes.add(newLike);
      }
    });

    postCubit.likePost(widget.post.id, newLike).catchError((e) {
      setState(() {
        if (isLiked) {
          widget.post.likes.add(newLike);
        } else {
          widget.post.likes
              .removeWhere((like) => like.likeuserid == currentUser!.uid);
        }
      });
    }).whenComplete(() {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          showSplash = false;
        });
      });
    });
  }

  void openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(hintText: 'Add Comment'),
          ),
          actions: [
            TextButton(
              onPressed: Addcomment,
              child: const Text('Add Comment'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void Addcomment() {
    setState(() {
      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        postId: widget.post.id,
        userId: currentUser!.uid,
        username: currentUser!.name,
        text: commentController.text,
        timestamp: DateTime.now(),
      );
      if (commentController.text.isNotEmpty) {
        widget.post.comments.add(newComment);
      }
    });
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: currentUser!.uid,
      username: currentUser!.name,
      text: commentController.text,
      timestamp: DateTime.now(),
    );
    if (commentController.text.isNotEmpty) {
      postCubit.addComment(widget.post.id, newComment);
    }
    commentController.clear();
    Navigator.pop(context);
  }

  void deleteComment(String commentId) {
    setState(() {
      widget.post.comments.removeWhere((element) => element.id == commentId);
    });
    postCubit.deleteComment(widget.post.id, commentId);
  }

  @override
  Widget build(BuildContext context) {
    // Only display the post if the user is following
    if (!widget.isFollowing && (postUser?.publicorprivate ?? true)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.secondary,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (postUser?.profileImageUrl != null)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(uid: postUser!.uid),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 8.0,
                        left: 8.0,
                        bottom: 8.0,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: postUser!.profileImageUrl,
                        height: 30,
                        width: 30,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          backgroundImage: imageProvider,
                        ),
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                        fit: BoxFit.fill,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.person),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.post.userName ?? 'no name',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const Spacer(),
                if (isOwnPost)
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
            Stack(alignment: Alignment.center, children: [
              GestureDetector(
                onDoubleTap: togglelike,
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl ??
                      'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd',
                  height: 300,
                  width: double.infinity,
                  placeholder: (context, url) => const SizedBox(
                    height: 10,
                    width: 10,
                    child: Center(child: Text('loading......')),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.cover,
                ),
              ),
              if (showSplash)
                Center(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 100,
                    ),
                  ),
                ),
            ]),
            Row(
              children: [
                GestureDetector(
                  onTap: togglelike,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8.0,
                      top: 8.0,
                      bottom: 8.0,
                      right: 2.0,
                    ),
                    child: Icon(
                      widget.post.likes.any(
                              (like) => like.likeuserid == currentUser!.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.post.likes.any(
                              (like) => like.likeuserid == currentUser!.uid)
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                ),
                Text(widget.post.likes.length.toString()),
                GestureDetector(
                  onTap: openNewCommentBox,
                  child: const Padding(
                    padding: EdgeInsets.only(
                      left: 8.0,
                      top: 8.0,
                      bottom: 8.0,
                      right: 2.0,
                    ),
                    child: Icon(Icons.chat),
                  ),
                ),
                Text(widget.post.comments.length.toString()),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 8.0,
                    top: 8.0,
                    bottom: 8.0,
                    right: 2.0,
                  ),
                  child: Text(
                    widget.post.timestamp.toString().substring(0, 11),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 2.0),
                  child: Text(
                    widget.post.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0, bottom: 8.0, right: 2.0),
                    child: Text(widget.post.text),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 2.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => Commentspage(post: widget.post)),
                  );
                },
                child: Text(
                  'Comments:',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ),
            BlocBuilder<PostCubit, Poststate>(
              builder: (context, state) {
                if (state is PostLoaded) {
                  final post = state.posts
                      .firstWhere((element) => element.id == widget.post.id);
                  if (post.comments.isNotEmpty) {
                    int showCommentcount = post.comments.length;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: showCommentcount < 2 ? showCommentcount : 2,
                      itemBuilder: (context, index) {
                        final comment = post.comments[index];
                        return Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 2.0),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfilePage(uid: comment.userId),
                                    ),
                                  );
                                },
                                child: Text(
                                  comment.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 2.0),
                                child: Text(comment.text),
                              ),
                            ),
                            const Spacer(),
                            if (comment.userId == currentUser!.uid)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    deleteComment(comment.id);
                                  },
                                  child: Icon(
                                    Icons.delete,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  }
                }
                if (state is PostLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No comments yet'),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

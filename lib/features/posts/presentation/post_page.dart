import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'components/posttile.dart';
import 'cubits/post_cubit.dart';
import 'cubits/post_states.dart';

class PostPage extends StatefulWidget {
  final String uid;
  final String? focusPostId;

  const PostPage({
    super.key,
    required this.uid,
    required this.focusPostId,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _scrollController = ScrollController();
  late final postCubit = context.read<PostCubit>();

  @override
  void initState() {
    postCubit.fetchAllPosts();
    super.initState();
  }

  // ignore: non_constant_identifier_names
  void DeletePost(String postId) {
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
                  child: const Text('Yes')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('No')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Posts'),
        ),
        body: BlocBuilder<PostCubit, Poststate>(builder: (context, state) {
          if (state is PostLoading || state is PostUploading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PostLoaded) {
            final allPosts =
                state.posts.where((post) => post.userId == widget.uid).toList();
            final index =
                allPosts.indexWhere((post) => post.id == widget.focusPostId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (index >= 0 && index < allPosts.length) {
                _scrollController.jumpTo(index * 400.0);
              }
            });
            if (allPosts.isEmpty) {
              return const Center(child: Text('No posts yet'));
            } else {
              return ListView.builder(
                controller: _scrollController,
                itemCount: allPosts.length,
                itemBuilder: (context, index) {
                  final post = allPosts[index];
                  return Posttile(
                      isFollowing: true,
                      post: post,
                      onDelete: () {
                        DeletePost(post.id);
                      });
                },
              );
            }
          } else if (state is PostError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        }));
  }
}

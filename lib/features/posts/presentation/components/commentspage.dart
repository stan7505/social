import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../profile/presentation/pages/profile_page.dart';
import '../../domain/entities/post.dart';
import '../cubits/post_cubit.dart';
import '../cubits/post_states.dart';

class Commentspage extends StatefulWidget {
  final Post post;

  const Commentspage({super.key, required this.post});

  @override
  State<Commentspage> createState() => _CommentspageState();
}

class _CommentspageState extends State<Commentspage> {
  late PostCubit postCubit;

  void deleteComment(String commentId) {
    setState(() {
      widget.post.comments.removeWhere((element) => element.id == commentId);
    });
    postCubit.deleteComment(widget.post.id, commentId);
  }

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: BlocBuilder<PostCubit, Poststate>(
        builder: (context, state) {
          if (state is PostLoaded) {
            final post = state.posts
                .firstWhere((element) => element.id == widget.post.id);
            if (post.comments.isNotEmpty) {
              int showCommentcount = post.comments.length;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: showCommentcount,
                itemBuilder: (context, index) {
                  final comment = post.comments[index];
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 2.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfilePage(uid: comment.userId),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                          DateFormat('yyyy-MM-dd – kk:mm')
                                              .format(comment.timestamp),
                                          style: const TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 50.0, right: 2.0),
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
    );
  }
}

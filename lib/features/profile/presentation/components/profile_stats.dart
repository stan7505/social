import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int postscount;
  final int followerscount;
  final int followingcount;
  final void Function()? onPressed;

  const ProfileStats(
      {super.key,
      required this.postscount,
      required this.followerscount,
      required this.followingcount,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  postscount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Posts',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  followerscount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Followers',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  followingcount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Following',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

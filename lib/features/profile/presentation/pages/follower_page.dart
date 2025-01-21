import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';

class FollowerPage extends StatelessWidget {
  final List<String> followers;
  final List<String> following;

  const FollowerPage({
    super.key,
    required this.followers,
    required this.following,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Followers'),
                  Tab(text: 'Following'),
                ],
              ),
            ),
            body: TabBarView(children: [
              _builduserList(followers, 'No followers yet', context),
              _builduserList(following, 'Not following anyone yet', context),
            ])));
  }

  Widget _builduserList(
      List<String> uids, String emptymessage, BuildContext context) {
    return uids.isEmpty
        ? Center(
            child: Text(emptymessage),
          )
        : ListView.builder(
            itemCount: uids.length,
            itemBuilder: (context, index) {
              final uid = uids[index];
              return FutureBuilder(
                future: context.read<ProfileCubit>().getUserProfile(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final user = snapshot.data;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user!.profileImageUrl),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.bio),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ProfilePage(
                              uid: user.uid,
                            ))),
                  );
                },
              );
            },
          );
  }
}

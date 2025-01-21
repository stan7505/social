import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/search/presentation/Cubits/search_cubit.dart';
import 'package:social/features/search/presentation/Cubits/search_states.dart';

import '../../../profile/presentation/pages/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final searchcubit = context.read<SearchCubit>();

  void onSearchChanged() {
    final query = _searchController.text;
    searchcubit.searchusers(query);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(builder: (context, state) {
        if (state is SearchLoadingState) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is SearchLoadedState) {
          final users = state.users;
          return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
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
              });
        }
        if (state is SearchErrorState) {
          return Center(
            child: Text(state.message),
          );
        }

        return const Center(
          child: Text('Search for users'),
        );
      }),
    );
  }
}

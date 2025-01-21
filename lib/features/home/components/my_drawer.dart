import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/profile/presentation/pages/profile_page.dart';

import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../search/presentation/pages/search_page.dart';
import '../../settings/presentation/pages/settings.dart';
import 'my_drawer_tile.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Icon(Icons.account_circle,
                  size: 100,
                  color: Theme.of(context).colorScheme.inversePrimary),
              const SizedBox(
                height: 20,
              ),
              Divider(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              MyDrawerTile(
                  title: 'Home',
                  icon: Icons.home,
                  onTap: () => Navigator.pop(context)),
              MyDrawerTile(
                  title: 'Profile',
                  icon: Icons.person,
                  onTap: () {
                    final currentUserId = context.read<AuthCubit>().currentUser;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(
                                  uid: currentUserId!.uid,
                                )));
                  }),
              MyDrawerTile(
                  title: 'Search',
                  icon: Icons.search,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchPage()));
                  }),
              MyDrawerTile(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()));
                  }),
              const Spacer(),
              MyDrawerTile(
                  title: 'Logout',
                  icon: Icons.logout,
                  onTap: () {
                    context.read<AuthCubit>().logOut();
                    setState(() {
                    });
                  }),
            ],
          ),
        ));
  }
}

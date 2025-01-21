import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/In%20App%20Notifications/presentation/pages/inapp_notification.dart';
import 'package:social/features/posts/presentation/upload_post.dart';
import 'package:social/features/search/presentation/pages/search_page.dart';
import '../../In App Notifications/presentation/states/inappnotific_states.dart';
import '../../In%20App%20Notifications/presentation/cubits/notification_cubits.dart';
import '../../auth/presentation/cubits/auth_cubit.dart';
import '../../profile/presentation/pages/profile_page.dart';
import 'home_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;
  late String currentUserUid;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final authCubit = context.read<AuthCubit>();
    currentUserUid = authCubit.currentUser!.uid;
    pages = [
      const HomePage(),
      const SearchPage(),
      const UploadPost(),
      const InappNotification(),
      ProfilePage(uid: currentUserUid),
    ];
  }

  void _onTabTapped(int index) {
    if (index >= 0 && index < pages.length) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        fixedColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface,
        onTap: _onTabTapped,
        currentIndex: currentIndex,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (currentUser != null)
                  BlocBuilder<NotificationCubit, NotificationState>(
                    builder: (context, state) {
                      if (state is NotificationLoaded &&
                          state.hasNewNotificationss) {
                        return Positioned(
                          right: 0,
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
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

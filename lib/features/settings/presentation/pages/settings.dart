import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../profile/presentation/cubits/profile_cubit.dart';
import '../../../profile/presentation/cubits/profile_states.dart';
import '../../../themes/presentation/themeswitch.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  var profileUser;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final profileCubit = context.read<ProfileCubit>();
    final profileState = profileCubit.state;
    final currentUserId = context.read<AuthCubit>().currentUser?.uid;

    if (profileState is ProfileLoaded) {
      profileUser = profileState.user;
    } else {
      if (currentUserId != null) {
        profileCubit.fetchUserProfile(currentUserId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthCubit>().currentUser?.uid;

    void togglePrivacy() {
      final profileCubit = context.read<ProfileCubit>();
      final profileState = profileCubit.state;
      if (profileState is! ProfileLoaded) {
        return;
      }
      profileUser = profileState.user;
      final newPrivacy = !profileUser.publicorprivate;

      // Update UI immediately
      setState(() {
        profileUser = profileUser.copyWith(newPublicorPrivate: newPrivacy);
        isLoading = true;
      });

      // Perform backend update
      profileCubit.togglePrivacy(currentUserId!).then((_) {
        profileCubit.fetchUserProfile(currentUserId).then((_) {
          setState(() {
            isLoading = false;
          });
        });
      }).catchError((e) {
        // Revert UI change on error
        setState(() {
          profileUser = profileUser.copyWith(newPublicorPrivate: !newPrivacy);
          isLoading = false;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Settings'),
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoaded) {
            profileUser = state.user;
          }
          // Show a loading indicator if user not loaded yet
          if (state is ProfileInitial || state is ProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          // Show error message if needed
          if (state is ProfileError) {
            return Center(
              child: Text('[Settings] Error: ${state.message}'),
            );
          }

          // Default UI if user is loaded
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          'Dark Mode',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      const Themeswitch(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          'Privacy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      isLoading
                          ? const CircularProgressIndicator()
                          : CupertinoSwitch(
                              value: profileUser?.publicorprivate ?? false,
                              onChanged: (_) {
                                togglePrivacy();
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

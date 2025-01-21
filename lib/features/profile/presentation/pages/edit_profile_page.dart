import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
//import this to use FilePicker
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // this package is used to check if the platform is web
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/presentation/components/text_field.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import 'package:social/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:social/features/profile/presentation/cubits/profile_states.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileUser user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  PlatformFile? imagePickedfile;
  Uint8List? imageWebBytes;
  final TextEditingController bioController = TextEditingController();

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result != null) {
      setState(() {
        imagePickedfile = result.files.first;
        if (kIsWeb) {
          imageWebBytes = imagePickedfile!.bytes;
        }
      });
    }
  }

  void updateprofile() async {
    final profileCubit = context.read<ProfileCubit>();
    final String? imageMobilePath = kIsWeb ? null : imagePickedfile?.path;
    final imageWebBytes = kIsWeb ? this.imageWebBytes : null;
    final String? newBio =
        bioController.text.isNotEmpty ? bioController.text : null;

    if (bioController.text.isNotEmpty || imagePickedfile != null) {
      profileCubit.updateProfile(
        uid: widget.user.uid,
        newBio: newBio,
        imageWebBytes: imageWebBytes,
        imageMobilePath: imageMobilePath,
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to update')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text('Updating....'),
                  ],
                ),
              ),
            ),
          );
        }

        return buildEditPage();
      },
      listener: (context, state) {
        if (state is ProfileError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is ProfileLoaded) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile Updated')));
          Navigator.pop(context);
        }
      },
    );
  }

  Widget buildEditPage() {
    ImageProvider? backgroundImage;
    if (!kIsWeb && imagePickedfile != null && imagePickedfile!.path != null) {
      backgroundImage = FileImage(File(imagePickedfile!.path!));
    } else if (kIsWeb && imageWebBytes != null) {
      backgroundImage = MemoryImage(imageWebBytes!);
    } else if (widget.user.profileImageUrl != null &&
        widget.user.profileImageUrl.isNotEmpty &&
        widget.user.profileImageUrl != 'null') {
      backgroundImage = CachedNetworkImageProvider(widget.user.profileImageUrl);
    } else {
      backgroundImage = const CachedNetworkImageProvider(
        'https://firebasestorage.googleapis.com/v0/b/social-media-app-52360.firebasestorage.app/o/defaults%2Fempty_profile_pic.png?alt=media&token=4dff2d94-4167-4283-b7bc-aa8c3462c9dd',
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          GestureDetector(
            onTap: updateprofile,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
        ],
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundImage: backgroundImage,
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.upload,
                    color: Colors.white.withOpacity(0.8),
                    size: 60,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Bio',
            style:
                TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: MyTextField(
              controller: bioController,
              hintText: widget.user.bio,
              obscureText: false,
              icon: null,
            ),
          ),
        ],
      ),
    );
  }
}

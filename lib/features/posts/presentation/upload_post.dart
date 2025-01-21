import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/domain/entities/app_user.dart';
import 'package:social/features/auth/presentation/components/text_field.dart';
import 'package:social/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:social/features/home/presentation/home_page.dart';
import 'package:social/features/posts/presentation/cubits/post_cubit.dart';
import 'package:social/features/posts/presentation/cubits/post_states.dart';
import 'package:social/features/profile/domain/entities/profile_user.dart';
import '../../profile/presentation/cubits/profile_cubit.dart';
import '../domain/entities/post.dart';

class UploadPost extends StatefulWidget {
  const UploadPost({super.key});

  @override
  State<UploadPost> createState() => _UploadPostState();
}

class _UploadPostState extends State<UploadPost> {
  AppUser? currentuser;
  ProfileUser? profileUser;
  PlatformFile? imagePickedfile;
  Uint8List? imageWebBytes;
  final TextEditingController caption = TextEditingController();

  @override
  void initState() {
    super.initState();
    getcurrentuser();
  }

  void getcurrentuser() async {
    final authCubit = context.read<AuthCubit>();
    currentuser = authCubit.currentUser;
    final uid = currentuser!.uid;
  }

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

  Future<bool> private() async {
    final authCubit = context.read<AuthCubit>();
    final uid = authCubit.currentUser!.uid;
    profileUser = await context.read<ProfileCubit>().getUserProfile(uid);
    if (profileUser != null) {
      return profileUser!.publicorprivate;
    } else {
      return true;
    }
  }

  Future<void> uploadpost() async {
    if (imagePickedfile == null || caption.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select an image and write a caption')));
      return;
    }
    final isPrivate = await private();
    final newpost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentuser!.uid,
      imageUrl: '',
      timestamp: DateTime.now(),
      userName: currentuser!.name,
      text: caption.text,
      likes: [],
      comments: [],
      private: isPrivate,
    );

    final postCubit = context.read<PostCubit>();

    if (kIsWeb) {
      postCubit.createPost(newpost, imageBytes: imageWebBytes);
    } else {
      postCubit.createPost(newpost, imagePath: imagePickedfile!.path);
    }
  }

  Widget builduploadPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        actions: [
          IconButton(
            onPressed: uploadpost,
            icon: const Icon(Icons.upload),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              if (kIsWeb && imageWebBytes != null) Image.memory(imageWebBytes!),
              if (!kIsWeb && imagePickedfile != null)
                Image.file(File(imagePickedfile!.path!)),
              MaterialButton(
                  onPressed: pickImage, child: const Icon(Icons.add_a_photo)),
              MyTextField(
                controller: caption,
                hintText: 'Caption',
                obscureText: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostCubit, Poststate>(
      builder: (context, state) {
        if (state is PostLoading || state is PostUploading) {
          return const Center(
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text('Uploading....'),
                  ],
                ),
              ),
            ),
          );
        }
        return builduploadPage();
      },
      listener: (context, state) {
        if (state is PostError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is PostUploaded) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Post Uploaded')));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      },
    );
  }
}

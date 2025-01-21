import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/my_button.dart';
import '../components/text_field.dart';
import '../cubits/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  final void Function() toggleLogin;

  const RegisterPage({super.key, required this.toggleLogin});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  void register() {
    final String email = emailController.text;
    final String password = passwordController.text;
    final String name = nameController.text;
    final String confirmPassword = confirmPasswordController.text;

    if (email.isNotEmpty &&
        password.isNotEmpty &&
        name.isNotEmpty &&
        confirmPassword.isNotEmpty) {
      if (password == confirmPassword) {
        final authCubit = context.read<AuthCubit>();
        authCubit.register(name, email, password);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Passwords do not match")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields")));
    }
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  bool obscureText = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void obscureTextToggle() {
      setState(() {
        obscureText = !obscureText;
      });
    }

    return Scaffold(
        body: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_circle,
                    size: 100, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 20),
                Text("Glad to have you on board!",
                    style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 20),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                  icon: Icons.email,
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: nameController,
                  hintText: 'Name',
                  obscureText: false,
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Enter your password',
                  obscureText: obscureText,
                  toggleVisibility: obscureTextToggle,
                  icon: Icons.lock,
                ),
                const SizedBox(
                  height: 20,
                ),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm your password',
                  obscureText: obscureText,
                  toggleVisibility: obscureTextToggle,
                  icon: Icons.lock,
                ),
                const SizedBox(height: 30),
                MyButton(onTap: register, text: 'Register'),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already a member?",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                    TextButton(
                        onPressed: widget.toggleLogin,
                        child: Text(
                          "Login",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

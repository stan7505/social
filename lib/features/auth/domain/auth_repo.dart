import 'package:social/features/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser> loginwithEmailAndPassword(String email, String password);

  Future<AppUser> registerwithEmailAndPassword(
      String name, String email, String password);

  Future<void> logOut();

  Future<AppUser?> getCurrentUser();
}

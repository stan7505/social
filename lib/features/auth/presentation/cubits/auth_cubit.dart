import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:social/features/auth/domain/auth_repo.dart';
import 'package:social/features/auth/domain/entities/app_user.dart';
import 'package:social/features/auth/presentation/cubits/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  void checkauth() async {
    final AppUser? user = await authRepo.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(UnAuthenticated());
    }
  }

  AppUser? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.loginwithEmailAndPassword(email, password);
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(UnAuthenticated());
        emit(AuthError(message: 'User not found'));
      }
    } catch (e) {
      emit(UnAuthenticated());
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      emit(AuthLoading());
      final user =
          await authRepo.registerwithEmailAndPassword(name, email, password);
      if (user != null) {
        _currentUser = user;
        emit(Authenticated(user));
      } else {
        emit(UnAuthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(UnAuthenticated());
    }
  }

  Future<void> logOut() async {
    await authRepo.logOut();
    _currentUser = null;
    emit(UnAuthenticated());
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Check Persistent Session on Startup
    on<CheckAuthRequested>((event, emit) async {
      final user = await authRepository.getPersistedSession();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });

    // Handle Sign In with Mobile Number & Password
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.signIn(
          phone: event.phone,
          password: event.password,
        );
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const AuthError('Login failed: Invalid response'));
        }
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    // Handle Sign Up
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.signUp(
          fullName: event.fullName,
          phone: event.phone,
          address: event.address,
          email: event.email,
          password: event.password,
        );
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const AuthError('Registration failed: Invalid response'));
        }
      } catch (e) {
        emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      }
    });

    // Handle Sign Out
    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(Unauthenticated());
    });

    on<UpdateUserSession>((event, emit) {
      emit(Authenticated(event.user));
    });

    on<UpdateProfileImageRequested>((event, emit) async {
      if (state is Authenticated) {
        final currentUser = (state as Authenticated).user;
        try {
          final imageUrl = await authRepository.uploadProfileImage(currentUser.id, event.imagePath);
          final updatedUser = currentUser.copyWith(profileImageUrl: imageUrl);
          await authRepository.saveSession(updatedUser);
          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError(e.toString().replaceAll('Exception: ', '')));
          emit(Authenticated(currentUser)); // Revert back to authenticated state
        }
      }
    });
  }
}
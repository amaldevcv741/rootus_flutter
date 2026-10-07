import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../core/services/firebase_messaging_service.dart';
import 'package:flutter/foundation.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Check Persistent Session on Startup
    on<CheckAuthRequested>((event, emit) async {
      final user = await authRepository.getPersistedSession();
      if (user != null) {
        emit(Authenticated(user));
        // Update FCM Token on startup
        FirebaseMessagingService.getToken().then((token) {
          if (token != null) {
             authRepository.updateFCMToken(user.id, token);
          }
        });
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
          // Ask for notification permission only after successful login
          try {
            await FirebaseMessagingService.requestPermission();
            final token = await FirebaseMessagingService.getToken();
            if (token != null) {
              await authRepository.updateFCMToken(user.id, token);
            }
          } catch (e) {
            debugPrint("Notification permission/token error post-login: $e");
          }
        } else {
          emit(const AuthError('Login failed: Invalid response'));
        }
      } catch (e) {
        emit(AuthError(ErrorHandler.clean(e)));
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
          profileImageUrl: event.profileImageUrl,
          latitude: event.latitude,
          longitude: event.longitude,
        );
        if (user != null) {
          emit(Authenticated(user));
          // Ask for notification permission only after successful signup/login
          try {
            await FirebaseMessagingService.requestPermission();
            final token = await FirebaseMessagingService.getToken();
            if (token != null) {
              await authRepository.updateFCMToken(user.id, token);
            }
          } catch (e) {
            debugPrint("Notification permission/token error post-signup: $e");
          }
        } else {
          emit(const AuthError('Registration failed: Invalid response'));
        }
      } catch (e) {
        emit(AuthError(ErrorHandler.clean(e)));
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
          final imageUrl = await authRepository.updateProfileImage(currentUser.id, event.profileImageUrl);
          final updatedUser = currentUser.copyWith(profileImageUrl: imageUrl);
          await authRepository.saveSession(updatedUser);
          emit(Authenticated(updatedUser));
        } catch (e) {
          emit(AuthError(ErrorHandler.clean(e)));
          emit(Authenticated(currentUser)); // Revert back to authenticated state
        }
      }
    });
    on<ResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await authRepository.resetPassword(
          phone: event.phone,
          newPassword: event.newPassword,
        );
        emit(ResetPasswordSuccess());
        emit(Unauthenticated());
      } catch (e) {
        emit(AuthError(ErrorHandler.clean(e)));
        emit(Unauthenticated());
      }
    });
  }
}
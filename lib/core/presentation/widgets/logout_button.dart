import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import 'app_dialogs.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  void _showLogoutDialog(BuildContext context) {
    AppDialogs.showConfirmationDialog(
      context: context,
      title: 'Logout',
      icon: Icons.logout,
      confirmText: 'Logout',
      confirmColor: const Color(0xFFEF4444),
      content: const Text(
        'Are you sure you want to log out of your account?',
        style: TextStyle(color: Color(0xFF94A3B8)),
      ),
      onConfirm: () {
        context.read<AuthBloc>().add(SignOutRequested());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
      onPressed: () => _showLogoutDialog(context),
      tooltip: 'Logout',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/data/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/presentation/widgets/logout_button.dart';
import '../../../core/presentation/widgets/app_dialogs.dart';
import '../../auth/presentation/map_selection_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../../core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  double? _newLatitude;
  double? _newLongitude;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showAvatarSelectionBottomSheet(BuildContext context) {
    final avatars = [
      '/uploads/avatars/male_1.webp',
      '/uploads/avatars/male_2.webp',
      '/uploads/avatars/male_3.webp',
      '/uploads/avatars/male_4.webp',
      '/uploads/avatars/male_5.webp',
      '/uploads/avatars/female_1.webp',
      '/uploads/avatars/female_2.webp',
      '/uploads/avatars/female_3.webp',
      '/uploads/avatars/female_4.webp',
      '/uploads/avatars/female_5.webp',
    ];

    final currentUser = context.read<AuthBloc>().state is Authenticated 
        ? (context.read<AuthBloc>().state as Authenticated).user 
        : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          color: const Color(0xFF1E293B), // Match dark theme
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose an Avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final avatarUrl = avatars[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        if (currentUser != null) {
                          context.read<AuthBloc>().add(UpdateProfileImageRequested(avatarUrl));
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentUser?.profileImageUrl == avatarUrl
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(ApiClient.baseUrl + avatarUrl),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
        actions: [
          StatefulBuilder(
            builder: (context, setStateDialog) {
              return AppDialogs.buildActionButtons(
                context: context,
                cancelText: 'Cancel',
                confirmText: 'Save',
                isLoading: _isLoading,
                onCancel: () {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  Navigator.pop(dialogContext);
                },
                onConfirm: () async {
                  if (_currentPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill all fields')),
                    );
                    return;
                  }
                  setStateDialog(() {
                    _isLoading = true;
                  });
                  try {
                    await context.read<AuthRepository>().changePassword(
                          userId: userId,
                          currentPassword: _currentPasswordController.text,
                          newPassword: _newPasswordController.text,
                        );
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      AppDialogs.showSuccessToast(context, 'Password changed successfully');
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setStateDialog(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
              );
            },
          ),
        ],
        );
      },
    );
  }

  void _showChangeAddressDialog(BuildContext context, AppUser user) {
    _addressController.text = user.address;
    _newLatitude = user.latitude;
    _newLongitude = user.longitude;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Address', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Delivery Address',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateLocal) {
                  return ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapSelectionScreen(
                            initialLatitude: _newLatitude,
                            initialLongitude: _newLongitude,
                          ),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        setStateLocal(() {
                          _newLatitude = result['latitude'];
                          _newLongitude = result['longitude'];
                        });
                        _addressController.text = result['address'];
                      }
                    },
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: const Text('Choose on Map', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 10),
          actions: [
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return AppDialogs.buildActionButtons(
                  context: context,
                  cancelText: 'Cancel',
                  confirmText: 'Save',
                  isLoading: _isLoading,
                  onCancel: () {
                    _addressController.clear();
                    Navigator.pop(dialogContext);
                  },
                  onConfirm: () async {
                    if (_addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an address')),
                      );
                      return;
                    }
                    setStateDialog(() {
                      _isLoading = true;
                    });
                    try {
                      final updatedUser = await context.read<AuthRepository>().changeAddress(
                            _addressController.text,
                            latitude: _newLatitude,
                            longitude: _newLongitude,
                          );
                      if (mounted && updatedUser != null) {
                        context.read<AuthBloc>().add(UpdateUserSession(updatedUser));
                        Navigator.pop(dialogContext);
                        AppDialogs.showSuccessToast(context, 'Address updated successfully');
                        _addressController.clear();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setStateDialog(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchWhatsApp() async {
    const adminPhone = "919380462741"; // Admin number (no +)
    const message = "Hi Rootus Farms, I need help.";
    final Uri whatsappUrl = Uri.parse("whatsapp://send?phone=$adminPhone&text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please ensure it is installed.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final user = state.user;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profile'),
              backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
              elevation: 0,
              actions: const [
                LogoutButton(),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<AuthBloc>();
                bloc.add(CheckAuthRequested());
                await bloc.stream.firstWhere((s) => s is Authenticated || s is Unauthenticated);
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showAvatarSelectionBottomSheet(context),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF334155),
                          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                              ? NetworkImage('${ApiClient.baseUrl}${user.profileImageUrl}')
                              : null,
                          child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        if (state is AuthLoading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.phone,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 40),
                  _buildProfileItem(Icons.email, 'Email', user.email.isEmpty ? 'Not provided' : user.email),
                  const SizedBox(height: 16),
                  _buildProfileItem(
                    Icons.location_on, 
                    'Address', 
                    user.address,
                    onEdit: () => _showChangeAddressDialog(context, user),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: _buildProfileItem(Icons.shopping_bag, 'My Orders', 'View order history and status', isClickable: true),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showChangePasswordDialog(context, user.id),
                      icon: const Icon(Icons.lock_outline, color: Colors.white),
                      label: const Text('Change Password', style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _launchWhatsApp,
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text('Chat with us on WhatsApp', style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value, {VoidCallback? onEdit, bool isClickable = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: onEdit,
            ),
          if (isClickable)
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

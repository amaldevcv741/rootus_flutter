import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter/material.dart';
import '../../features/products/presentation/home_screen.dart';
import '../../features/home/presentation/farm_web_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FarmWebScreen(),
    const HomeScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: GNav(
            backgroundColor: const Color(0xFF1E293B),
            color: const Color(0xFF94A3B8),
            activeColor: Colors.white,
            tabBackgroundColor: AppColors.primary,
            gap: 8,
            padding: const EdgeInsets.all(12),
            selectedIndex: _currentIndex,
            onTabChange: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home',
              ),
              GButton(
                icon: Icons.storefront,
                text: 'Products',
              ),
              GButton(
                icon: Icons.shopping_cart,
                text: 'Cart',
              ),
              GButton(
                icon: Icons.person,
                text: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

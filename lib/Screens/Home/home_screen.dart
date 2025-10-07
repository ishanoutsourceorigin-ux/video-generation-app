import 'package:flutter/material.dart';
import 'package:video_gen_app/Screens/dashboard_screen.dart';
import 'package:video_gen_app/Screens/Avatar/my_avatars_screen.dart';
import 'package:video_gen_app/Screens/Video/create_video.dart';
import 'package:video_gen_app/Screens/Project/project_screen.dart';
import 'package:video_gen_app/Screens/Settings/settings_screen.dart';
import 'package:video_gen_app/Utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<String> _titles = [
    "Dashboard",
    "My Avatar",
    "Create New",
    "Projects",
    "Settings",
  ];

  final List<String> _iconPaths = [
    "images/bottom-bar-icon/dashboard.png",
    "images/bottom-bar-icon/my-avatar.png",
    "images/bottom-bar-icon/create-new-video.png",
    "images/bottom-bar-icon/projects.png",
    "images/bottom-bar-icon/settings.png",
  ];

  final List<Widget> _screens = [
    DashboardScreen(showAppBar: false),
    MyAvatarsScreen(showAppBar: false),
    CreateVideo(showAppBar: false),
    ProjectsScreen(showAppBar: false),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBgColor,

      /// ✅ AnimatedSwitcher for smooth transitions between screens
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          // Slide + Fade animation
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0), // from right
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _selectedIndex >= 0 && _selectedIndex < _screens.length
            ? _screens[_selectedIndex]
            : _screens[0],
      ),

      /// ✅ Custom Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1), // Purple-blue
              const Color(0xFF8B5CF6), // Purple
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_titles.length, (index) {
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Image.asset(
                          _iconPaths[index],
                          height: 26,
                          width: 26,
                          color: Colors.white,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to default icons if image not found
                            IconData fallbackIcon;
                            switch (index) {
                              case 0:
                                fallbackIcon = Icons.dashboard;
                                break;
                              case 1:
                                fallbackIcon = Icons.person;
                                break;
                              case 2:
                                fallbackIcon = Icons.add_circle;
                                break;
                              case 3:
                                fallbackIcon = Icons.folder;
                                break;
                              case 4:
                                fallbackIcon = Icons.settings;
                                break;
                              default:
                                fallbackIcon = Icons.circle;
                            }
                            return Icon(
                              fallbackIcon,
                              size: 26,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1,
                          child: Text(
                            _titles[index],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

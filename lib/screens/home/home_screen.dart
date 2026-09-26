import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../feed/feed_screen.dart';
import '../chat/chat_list_screen.dart';
import '../call/teacher_directory_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    FeedScreen(),
    TeacherDirectoryScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed, color: AppColors.primary), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.video_call_outlined), selectedIcon: Icon(Icons.video_call, color: AppColors.primary), label: 'ติวสด'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary), label: 'แชท'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.primary), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

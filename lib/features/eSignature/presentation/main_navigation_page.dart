import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'upload_page.dart';
import 'pdf_list_page.dart';
import '../../auth/presentation/profile_page.dart';
import 'controllers/navigation_controller.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final NavigationController _navController;
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const PdfListPage(),
    const UploadPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _navController = Get.put(NavigationController());
    _navController.currentTabIndex.value = _currentIndex;
    _navController.currentTabIndex.listen((index) {
      if (mounted) {
        setState(() => _currentIndex = index);
      }
    });
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you want to exit the app?"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Exit"),
          ),
        ],
      ),
    );

    if (shouldExit == true && (Platform.isAndroid || Platform.isIOS)) {
      exit(0);
    }
    return shouldExit == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _navController.setTab(index);
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder),
              label: 'My PDFs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.upload_file),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

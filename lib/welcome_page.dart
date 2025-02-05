import 'package:flutter/material.dart';
import 'home_page.dart';
import 'schedule_page.dart';
import 'attendance_page.dart';
import 'notice_page.dart';
import 'profile_page.dart';

class WelcomePage extends StatefulWidget {
  final String username;

  const WelcomePage({super.key, required this.username});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AnnouncementsPage(username: widget.username),
      SchedulePage(username: widget.username),
      AttendancePage(userName: widget.username),
      NoticePage(),
      ProfilePage(username: widget.username),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.username}!'),
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex], // Display selected tab's content
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Highlight the selected item
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped, // Handle tab change
      ),
    );
  }
}

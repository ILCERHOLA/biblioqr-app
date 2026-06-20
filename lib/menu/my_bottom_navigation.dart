import 'package:flutter/material.dart';
import '../pages/home_page.dart';
import '../pages/nuevo_prestamo_page.dart';
import '../pages/historial_page.dart';
import '../pages/recordatorio_page.dart';
import '../pages/users_page.dart';

class MyBottomNavigation extends StatefulWidget {
  const MyBottomNavigation({super.key});

  @override
  State<MyBottomNavigation> createState() => _MyBottomNavigationState();
}

class _MyBottomNavigationState extends State<MyBottomNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NuevoPrestamoPage(),
    const HistorialPage(),
    const RecordatorioPage(),
    const UsersPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Catálogo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code), label: 'Préstamo'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Recordatorios'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Usuarios'),
        ],
      ),
    );
  }
}

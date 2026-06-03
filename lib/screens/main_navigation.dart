import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'nuevo_prestamo_screen.dart';
import 'historial_screen.dart';
import 'recordatorio_screen.dart';
import 'users_screen.dart'; // 🔹 nuevo import

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 🔹 Agregamos UsersScreen a la lista de pantallas
  final List<Widget> _screens = [
    const HomeScreen(),
    const NuevoPrestamoScreen(),
    const HistorialScreen(),
    const RecordatorioScreen(),
    const UsersScreen(), // 👈 nueva pantalla
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType
            .fixed, // 🔹 asegura que se muestren todos los ítems
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Préstamo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Recordatorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Usuarios', // 👈 nuevo ítem
          ),
        ],
      ),
    );
  }
}

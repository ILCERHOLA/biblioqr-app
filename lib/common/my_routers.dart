import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/add_book_page.dart';
import '../pages/recordatorio_page.dart';
import '../pages/users_page.dart';
import '../pages/historial_page.dart';
import '../pages/nuevo_prestamo_page.dart';
import '../menu/my_bottom_navigation.dart';

class MyRouters {
  static Map<String, WidgetBuilder> get routes => {
    '/login':        (context) => const LoginPage(),
    '/register':     (context) => const RegisterPage(),
    '/home':         (context) => const MyBottomNavigation(),
    '/addBook':      (context) => const AddBookPage(),
    '/recordatorio': (context) => const RecordatorioPage(),
    '/usuarios':     (context) => const UsersPage(),
    '/prestamo':     (context) => const NuevoPrestamoPage(),
    '/historial':    (context) => const HistorialPage(),
  };
}

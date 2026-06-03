import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// 🔹 Importar pantallas
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_book_screen.dart';
import 'screens/recordatorio_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/users_screen.dart';
import 'screens/historial_prestamos_screen.dart'; // ✅ nueva pantalla de historial

// 🔹 Declarar el plugin de notificaciones
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔹 Clave global para navegación desde notificaciones
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Firebase con archivo generado
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Configuración de inicialización para Android
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  // ✅ Inicialización correcta para versión 21.0.0
  await flutterLocalNotificationsPlugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('Notificación seleccionada: ${response.payload}');
      if (response.payload == 'home') {
        navigatorKey.currentState?.pushNamed('/home');
      }
    },
  );

  // 🔹 Crear canal de notificación (Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'recordatorio_channel', // ID único
    'Recordatorios', // Nombre visible
    description: 'Canal para notificaciones de devolución de libros',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:
          navigatorKey, // 👈 necesario para navegación desde notificaciones
      title: 'BiblioQR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => MainNavigation(),
        '/addBook': (context) => const AddBookScreen(),
        '/recordatorio': (context) => const RecordatorioScreen(),
        '/usuarios': (context) => const UsersScreen(),
        '/historial': (context) =>
            const HistorialPrestamosScreen(), // ✅ nueva ruta
      },
    );
  }
}

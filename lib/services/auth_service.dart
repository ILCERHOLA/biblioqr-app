import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ Servicio centralizado para verificar el rol del usuario actual.
/// Se usa en cualquier pantalla que necesite saber si el usuario
/// logueado es administrador antes de mostrar opciones sensibles.
class AuthService {
  static Future<String> obtenerRolActual() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'lector';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['rol'] ?? 'lector').toString().toLowerCase();
      }
    } catch (_) {}

    return 'lector';
  }

  static Future<bool> esAdministrador() async {
    final rol = await obtenerRolActual();
    return rol == 'administrador';
  }
}

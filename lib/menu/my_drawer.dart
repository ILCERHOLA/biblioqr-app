import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    // ✅ Confirmación antes de cerrar sesión
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header con datos del usuario
            FutureBuilder<DocumentSnapshot>(
              future: user != null
                  ? FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(user.uid)
                        .get()
                  : null,
              builder: (context, snapshot) {
                String nombre = 'Usuario';
                String correo = user?.email ?? '';
                String rol = 'lector';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  nombre = data['nombre'] ?? 'Usuario';
                  correo = data['correo'] ?? correo;
                  rol = data['rol'] ?? 'lector';
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _iniciales(nombre),
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        correo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          rol[0].toUpperCase() + rol.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Opciones del menú
            FutureBuilder<String>(
              future: AuthService.obtenerRolActual(),
              builder: (context, rolSnapshot) {
                final esAdmin = rolSnapshot.data == 'administrador';
                return Column(
                  children: [
                    if (esAdmin)
                      ListTile(
                        leading: const Icon(
                          Icons.people_outline,
                          color: Color(0xFF1565C0),
                        ),
                        title: const Text('Gestionar usuarios'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/usuarios');
                        },
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.library_books_outlined,
                        color: Color(0xFF1565C0),
                      ),
                      title: const Text('Catálogo'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Color(0xFF1565C0),
                      ),
                      title: const Text('Historial'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/historial');
                      },
                    ),
                  ],
                );
              },
            ),

            const Spacer(),

            const Divider(height: 1),

            // Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFC62828)),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _cerrarSesion(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

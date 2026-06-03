import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  Color _colorRol(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return const Color(0xFF1565C0);
      case 'estudiante':
        return const Color(0xFF2E7D32);
      case 'lector':
        return const Color(0xFF6A1B9A);
      default:
        return Colors.grey;
    }
  }

  Color _colorRolFondo(String rol) {
    switch (rol.toLowerCase()) {
      case 'administrador':
        return const Color(0xFFE3F2FD);
      case 'estudiante':
        return const Color(0xFFE8F5E9);
      case 'lector':
        return const Color(0xFFF3E5F5);
      default:
        return Colors.grey.shade100;
    }
  }

  void _cambiarRol(BuildContext context, String userId, String rolActual) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cambiar rol',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            ...['lector', 'estudiante', 'administrador'].map((rol) {
              final selected = rol == rolActual.toLowerCase();
              return ListTile(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(userId)
                      .update({'rol': rol});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rol actualizado a "$rol"'),
                      backgroundColor: const Color(0xFF1565C0),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorRolFondo(rol),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rol == 'administrador'
                        ? Icons.admin_panel_settings_outlined
                        : rol == 'estudiante'
                        ? Icons.school_outlined
                        : Icons.menu_book_outlined,
                    color: _colorRol(rol),
                    size: 18,
                  ),
                ),
                title: Text(
                  _capitalize(rol),
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? _colorRol(rol) : const Color(0xFF1A1A2E),
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded, color: _colorRol(rol))
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: const Text(
          'Usuarios registrados',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar usuarios'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          final usuarios = snapshot.data!.docs;

          if (usuarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay usuarios registrados',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final data = usuarios[index].data() as Map<String, dynamic>;
              final userId = usuarios[index].id;
              final nombre = data['nombre'] ?? 'Sin nombre';
              final correo = data['correo'] ?? 'Sin correo';
              final rol = data['rol'] ?? 'lector';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _iniciales(nombre),
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  subtitle: Text(
                    correo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: GestureDetector(
                    onTap: () => _cambiarRol(context, userId, rol),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _colorRolFondo(rol),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _capitalize(rol),
                            style: TextStyle(
                              color: _colorRol(rol),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more,
                            size: 14,
                            color: _colorRol(rol),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

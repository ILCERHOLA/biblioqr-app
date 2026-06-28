import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/prestamo_card.dart';

class ActivosFragment extends StatelessWidget {
  const ActivosFragment({super.key});

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('prestamos')
          .where('usuarioId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1565C0)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Error al cargar el historial',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final estado = (data['estado'] ?? '').toString().toLowerCase();
          return ['prestado', 'vencido'].contains(estado);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded,
                    size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 14),
                Text('No hay préstamos activos',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return PrestamoCard(
              titulo: _capitalize(data['libroTitulo'] ?? 'Sin título'),
              usuario: data['usuarioNombre'] ?? 'Usuario',
              estado: data['estado'] ?? 'Prestado',
              fechaDevolucion: data['fechaDevolucion'],
              portadaUrl: data['portadaUrl'],
              mostrarDias: true,
            );
          },
        );
      },
    );
  }
}

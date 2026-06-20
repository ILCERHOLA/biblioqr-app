import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../menu/fragments/activos_fragment.dart';
import '../menu/fragments/completados_fragment.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _verificarVencimientos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verificarVencimientos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ahora = DateTime.now();
    if (userId.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('usuarioId', isEqualTo: userId)
          .get();

      final prestados = snapshot.docs.where((doc) {
        final data = doc.data();
        return (data['estado'] ?? '').toString().toLowerCase() == 'prestado';
      }).toList();

      for (final doc in prestados) {
        final data = doc.data();
        final fechaDevolucion = data['fechaDevolucion'];
        if (fechaDevolucion == null) continue;

        final fecha = (fechaDevolucion as Timestamp).toDate();
        if (!ahora.isAfter(fecha)) continue;

        await doc.reference.update({'estado': 'Vencido'});

        final libroId = data['libroId']?.toString() ?? '';
        final libroTitulo = data['libroTitulo']?.toString() ?? '';
        bool actualizado = false;

        if (libroId.length > 10 && !libroId.contains(' ')) {
          try {
            await FirebaseFirestore.instance
                .collection('libros')
                .doc(libroId)
                .update({'estado': 'Vencido'});
            actualizado = true;
          } catch (_) {}
        }

        if (!actualizado && libroTitulo.isNotEmpty) {
          var query = await FirebaseFirestore.instance
              .collection('libros')
              .where('titulo', isEqualTo: libroTitulo)
              .limit(1)
              .get();

          if (query.docs.isEmpty) {
            final cap = libroTitulo[0].toUpperCase() + libroTitulo.substring(1);
            query = await FirebaseFirestore.instance
                .collection('libros')
                .where('titulo', isEqualTo: cap)
                .limit(1)
                .get();
          }

          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update({'estado': 'Vencido'});
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando vencimientos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: const Text(
          'Historial de préstamos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Completados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActivosFragment(),
          CompletadosFragment(),
        ],
      ),
    );
  }
}

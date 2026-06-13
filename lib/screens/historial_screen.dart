import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen>
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

    debugPrint('=== Verificando vencimientos ===');
    debugPrint('UserId: $userId');
    debugPrint('Ahora: $ahora');

    if (userId.isEmpty) {
      debugPrint('ERROR: userId vacío');
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('usuarioId', isEqualTo: userId)
          .get();

      debugPrint('Total préstamos encontrados: ${snapshot.docs.length}');

      final prestados = snapshot.docs.where((doc) {
        final data = doc.data();
        final estado = (data['estado'] ?? '').toString();
        debugPrint('Doc: ${doc.id} | estado: $estado');
        return estado.toLowerCase() == 'prestado';
      }).toList();

      debugPrint('Prestados: ${prestados.length}');

      for (final doc in prestados) {
        final data = doc.data();
        final fechaDevolucion = data['fechaDevolucion'];
        if (fechaDevolucion == null) {
          debugPrint('Sin fecha: ${doc.id}');
          continue;
        }

        final fecha = (fechaDevolucion as Timestamp).toDate();
        debugPrint(
          'Fecha devolución: $fecha | Venció: ${ahora.isAfter(fecha)}',
        );

        if (!ahora.isAfter(fecha)) continue;

        debugPrint('Actualizando a Vencido: ${doc.id}');
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
            debugPrint('Libro actualizado por ID: $libroId');
          } catch (_) {}
        }

        if (!actualizado && libroTitulo.isNotEmpty) {
          var query = await FirebaseFirestore.instance
              .collection('libros')
              .where('titulo', isEqualTo: libroTitulo)
              .limit(1)
              .get();

          if (query.docs.isEmpty) {
            final capitalizado =
                libroTitulo[0].toUpperCase() + libroTitulo.substring(1);
            query = await FirebaseFirestore.instance
                .collection('libros')
                .where('titulo', isEqualTo: capitalizado)
                .limit(1)
                .get();
          }

          if (query.docs.isNotEmpty) {
            await query.docs.first.reference.update({'estado': 'Vencido'});
            debugPrint('Libro actualizado por título: $libroTitulo');
          } else {
            debugPrint('Libro NO encontrado: $libroTitulo');
          }
        }
      }
      debugPrint('=== Verificación completada ===');
    } catch (e) {
      debugPrint('Error verificando vencimientos: $e');
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'prestado':
        return const Color(0xFF1565C0);
      case 'vencido':
        return const Color(0xFFC62828);
      case 'devuelto':
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  Color _colorEstadoFondo(String estado) {
    switch (estado.toLowerCase()) {
      case 'prestado':
        return const Color(0xFFE3F2FD);
      case 'vencido':
        return const Color(0xFFFFEBEE);
      case 'devuelto':
        return const Color(0xFFE8F5E9);
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatFecha(dynamic timestamp) {
    if (timestamp == null) return '—';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _diasRestantes(dynamic timestamp) {
    if (timestamp == null) return '';
    final fecha = (timestamp as Timestamp).toDate();
    final diff = fecha.difference(DateTime.now()).inDays;
    if (diff > 0) return 'Vence en $diff día${diff == 1 ? '' : 's'}';
    if (diff == 0) return '¡Vence hoy!';
    return 'Venció hace ${diff.abs()} día${diff.abs() == 1 ? '' : 's'}';
  }

  Color _colorDias(dynamic timestamp) {
    if (timestamp == null) return Colors.grey;
    final fecha = (timestamp as Timestamp).toDate();
    final diff = fecha.difference(DateTime.now()).inDays;
    if (diff > 3) return const Color(0xFF2E7D32);
    if (diff >= 0) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Widget _buildLista(List<String> estados) {
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
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Error al cargar el historial',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final estado = (data['estado'] ?? '').toString().toLowerCase();
          return estados.contains(estado);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  size: 64,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 14),
                Text(
                  estados.contains('devuelto')
                      ? 'No hay préstamos completados'
                      : 'No hay préstamos activos',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final titulo = _capitalize(data['libroTitulo'] ?? 'Sin título');
            final usuario = data['usuarioNombre'] ?? 'Usuario';
            final estado = data['estado'] ?? 'Prestado';
            final fechaDevolucion = data['fechaDevolucion'];
            final portadaUrl = data['portadaUrl'];
            final esActivo = estados.contains('prestado');

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: portadaUrl != null
                          ? Image.network(
                              portadaUrl,
                              width: 52,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                usuario,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_outlined,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Devolución: ${_formatFecha(fechaDevolucion)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (esActivo && fechaDevolucion != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _diasRestantes(fechaDevolucion),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _colorDias(fechaDevolucion),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _colorEstadoFondo(estado),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _capitalize(estado),
                        style: TextStyle(
                          color: _colorEstado(estado),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFF1565C0),
        size: 26,
      ),
    );
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Completados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLista(['prestado', 'vencido']),
          _buildLista(['devuelto']),
        ],
      ),
    );
  }
}

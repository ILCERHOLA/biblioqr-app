import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistorialPrestamosScreen extends StatefulWidget {
  const HistorialPrestamosScreen({super.key});

  @override
  State<HistorialPrestamosScreen> createState() =>
      _HistorialPrestamosScreenState();
}

class _HistorialPrestamosScreenState extends State<HistorialPrestamosScreen> {
  String filtroBusqueda = '';
  String filtroEstado = 'Todos';
  final formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de préstamos')),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Campo de búsqueda
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar por título',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (valor) {
                  setState(() {
                    filtroBusqueda = valor.trim().toLowerCase();
                  });
                },
              ),
            ),

            // ⚙️ Filtros por estado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButtonFormField<String>(
                initialValue: filtroEstado,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Prestado', child: Text('Prestados')),
                  DropdownMenuItem(value: 'Devuelto', child: Text('Devueltos')),
                  DropdownMenuItem(value: 'Vencido', child: Text('Vencidos')),
                ],
                onChanged: (valor) {
                  setState(() {
                    filtroEstado = valor!;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            // 📋 Lista dinámica
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('prestamos')
                    .where('usuarioId', isEqualTo: userId)
                    .orderBy('fechaPrestamo', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('❌ Error al cargar datos'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final prestamos = snapshot.data?.docs ?? [];

                  // ✅ Normalizar títulos y aplicar filtros
                  final filtrados = prestamos.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final titulo = (data['libroTitulo'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase();
                    final estado = data['estado'] ?? 'Desconocido';

                    final coincideBusqueda = titulo.contains(filtroBusqueda);
                    final coincideEstado =
                        filtroEstado == 'Todos' || estado == filtroEstado;

                    return coincideBusqueda && coincideEstado;
                  }).toList();

                  // ✅ Eliminar duplicados por título y usuario
                  final vistos = <String>{};
                  final prestamosUnicos = filtrados.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final clave =
                        '${data['libroTitulo']}_${data['usuarioNombre']}';
                    if (vistos.contains(clave)) return false;
                    vistos.add(clave);
                    return true;
                  }).toList();

                  if (prestamosUnicos.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron préstamos.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: prestamosUnicos.length,
                    itemBuilder: (context, index) {
                      final data =
                          prestamosUnicos[index].data() as Map<String, dynamic>;
                      final titulo = (data['libroTitulo'] ?? 'Sin título')
                          .toString()
                          .trim();
                      final usuario = data['usuarioNombre'] ?? 'Sin usuario';
                      final estado = data['estado'] ?? 'Desconocido';
                      final fechaPrestamo = (data['fechaPrestamo'] as Timestamp)
                          .toDate();
                      final fechaDevolucion =
                          (data['fechaDevolucion'] as Timestamp).toDate();

                      // ✅ Ícono y color según estado
                      IconData icono;
                      Color color;
                      switch (estado) {
                        case 'Disponible':
                          icono = Icons.check_circle;
                          color = Colors.green;
                          break;
                        case 'Prestado':
                          icono = Icons.menu_book;
                          color = Colors.blue;
                          break;
                        case 'Devuelto':
                          icono = Icons.done;
                          color = Colors.grey;
                          break;
                        case 'Vencido':
                          icono = Icons.warning;
                          color = Colors.orange;
                          break;
                        default:
                          icono = Icons.help_outline;
                          color = Colors.black54;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 12,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(icono, color: color),
                          title: Text(
                            titulo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '$usuario\nEstado: $estado\n'
                            'Préstamo: ${formatoFecha.format(fechaPrestamo)}\n'
                            'Devolución: ${formatoFecha.format(fechaDevolucion)}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

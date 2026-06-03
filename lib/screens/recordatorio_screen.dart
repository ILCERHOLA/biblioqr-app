import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class RecordatorioScreen extends StatelessWidget {
  const RecordatorioScreen({super.key});

  Future<void> mostrarRecordatorio() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'recordatorio_channel',
          'Recordatorios',
          channelDescription: 'Notificaciones de devolución de libros',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Recordatorio',
      body: 'No olvides devolver tu libro hoy',
      notificationDetails: notificationDetails,
    );
  }

  String _formatFecha(dynamic timestamp) {
    if (timestamp == null) return '—';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  bool _estaVencido(dynamic timestamp) {
    if (timestamp == null) return false;
    final date = (timestamp as Timestamp).toDate();
    return DateTime.now().isAfter(date);
  }

  bool _venceProximo(dynamic timestamp) {
    if (timestamp == null) return false;
    final date = (timestamp as Timestamp).toDate();
    final diff = date.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: const Text(
          'Recordatorios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('prestamos')
            .where('usuarioId', isEqualTo: userId)
            .where('estado', isEqualTo: 'Prestado')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          final prestamos = snapshot.data?.docs ?? [];
          final pendientes = prestamos.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _estaVencido(data['fechaDevolucion']) ||
                _venceProximo(data['fechaDevolucion']);
          }).toList();

          if (pendientes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Todo al día!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No tienes devoluciones pendientes',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: mostrarRecordatorio,
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF1565C0),
                    ),
                    label: const Text(
                      'Probar notificación',
                      style: TextStyle(color: Color(0xFF1565C0)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendientes.length,
            itemBuilder: (context, i) {
              final data = pendientes[i].data() as Map<String, dynamic>;
              final titulo = _capitalize(data['libroTitulo'] ?? 'Sin título');
              final fechaDevolucion = data['fechaDevolucion'];
              final vencido = _estaVencido(fechaDevolucion);
              final portadaUrl = data['portadaUrl'];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: vencido
                        ? const Color(0xFFEF9A9A)
                        : const Color(0xFFFFCC80),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Portada
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: portadaUrl != null
                                ? Image.network(
                                    portadaUrl,
                                    width: 56,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholder(),
                                  )
                                : _placeholder(),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge vencido/próximo
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: vencido
                                        ? const Color(0xFFFFEBEE)
                                        : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        vencido
                                            ? Icons.warning_amber_rounded
                                            : Icons.access_time_rounded,
                                        size: 13,
                                        color: vencido
                                            ? const Color(0xFFC62828)
                                            : const Color(0xFFE65100),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        vencido ? '¡Vencido!' : 'Vence pronto',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: vencido
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '¡Devolución pendiente!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: vencido
                                        ? const Color(0xFFC62828)
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Devolver "$titulo"',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'antes del ${_formatFecha(fechaDevolucion)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/historial'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Ver detalles',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await mostrarRecordatorio();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Recordatorio pospuesto',
                                    ),
                                    backgroundColor: const Color(0xFF1565C0),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey,
                                side: const BorderSide(
                                  color: Color(0xFFE0E0E0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Posponer',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Color(0xFF1565C0),
        size: 28,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'estado_chip.dart';
import 'libro_placeholder.dart';

class PrestamoCard extends StatelessWidget {
  final String titulo;
  final String usuario;
  final String estado;
  final dynamic fechaDevolucion;
  final String? portadaUrl;
  final bool mostrarDias;

  const PrestamoCard({
    super.key,
    required this.titulo,
    required this.usuario,
    required this.estado,
    this.fechaDevolucion,
    this.portadaUrl,
    this.mostrarDias = false,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                      portadaUrl!,
                      width: 52,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const LibroPlaceholder(),
                    )
                  : const LibroPlaceholder(),
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
                  if (mostrarDias && fechaDevolucion != null) ...[
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
            EstadoChip(estado: estado),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'estado_chip.dart';
import 'libro_placeholder.dart';

class LibroCard extends StatelessWidget {
  final String titulo;
  final String autor;
  final String estado;
  final String? portadaUrl;
  final int vecesPresado;
  final VoidCallback? onTap;

  const LibroCard({
    super.key,
    required this.titulo,
    required this.autor,
    required this.estado,
    this.portadaUrl,
    this.vecesPresado = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: portadaUrl != null
                ? Image.network(
                    portadaUrl!,
                    width: 46,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const LibroPlaceholder(width: 46, height: 60),
                  )
                : const LibroPlaceholder(width: 46, height: 60),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A2E),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                autor,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (vecesPresado > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 12,
                      color: Color(0xFF1565C0),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Prestado $vecesPresado ${vecesPresado == 1 ? 'vez' : 'veces'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          trailing: EstadoChip(estado: estado),
        ),
      ),
    );
  }
}

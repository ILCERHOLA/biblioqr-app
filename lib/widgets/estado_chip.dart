import 'package:flutter/material.dart';

class EstadoChip extends StatelessWidget {
  final String estado;

  const EstadoChip({super.key, required this.estado});

  Color get _color {
    switch (estado.toLowerCase()) {
      case 'disponible': return const Color(0xFF2E7D32);
      case 'prestado':   return const Color(0xFF1565C0);
      case 'vencido':    return const Color(0xFFC62828);
      case 'devuelto':   return const Color(0xFF2E7D32);
      default:           return Colors.grey;
    }
  }

  Color get _fondo {
    switch (estado.toLowerCase()) {
      case 'disponible': return const Color(0xFFE8F5E9);
      case 'prestado':   return const Color(0xFFE3F2FD);
      case 'vencido':    return const Color(0xFFFFEBEE);
      case 'devuelto':   return const Color(0xFFE8F5E9);
      default:           return Colors.grey.shade100;
    }
  }

  String get _texto {
    if (estado.isEmpty) return estado;
    return estado[0].toUpperCase() + estado.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _texto,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

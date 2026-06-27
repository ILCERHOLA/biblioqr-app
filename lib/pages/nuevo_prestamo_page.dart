import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';

class NuevoPrestamoPage extends StatefulWidget {
  const NuevoPrestamoPage({super.key});

  @override
  State<NuevoPrestamoPage> createState() => _NuevoPrestamoPageState();
}

class _NuevoPrestamoPageState extends State<NuevoPrestamoPage> {
  DateTime fechaPrestamo = DateTime.now();
  DateTime fechaDevolucion = DateTime.now().add(const Duration(days: 7));
  String libroTitulo = '';
  String? libroId;
  bool _isLoading = false;

  final _usuarioController = TextEditingController();
  final _libroController = TextEditingController();

  Future<void> programarRecordatorio(
    DateTime fechaDevolucion,
    String libroTitulo,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'recordatorio_channel',
          'Recordatorios',
          channelDescription:
              'Canal para notificaciones de devolución de libros',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: 0,
      title: 'Recordatorio de devolución',
      body: 'Recuerda devolver "$libroTitulo" mañana.',
      scheduledDate: tz.TZDateTime.from(
        fechaDevolucion.subtract(const Duration(days: 1)),
        tz.local,
      ),
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _scanQR(BuildContext context) async {
    final controller = MobileScannerController();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1565C0),
            title: const Text(
              'Escanear QR',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: controller,
                onDetect: (capture) async {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String id = barcodes.first.rawValue ?? '';
                    if (id.isNotEmpty) {
                      Navigator.pop(context);
                      setState(() {
                        libroId = id;
                        _libroController.text = id;
                        libroTitulo = id;
                      });
                      _showSnackBar('Libro escaneado correctamente');
                    }
                  }
                },
              ),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      _corner(top: 0, left: 0, rotate: 0),
                      _corner(top: 0, right: 0, rotate: 90),
                      _corner(bottom: 0, right: 0, rotate: 180),
                      _corner(bottom: 0, left: 0, rotate: 270),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Text(
                  'Apunta al código QR del libro',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotate,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotate * 3.14159 / 180,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF1565C0), width: 4),
              left: BorderSide(color: Color(0xFF1565C0), width: 4),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registrarPrestamo() async {
    final usuario = _usuarioController.text.trim();
    final libro = _libroController.text.trim();

    if (usuario.isEmpty) {
      _showSnackBar('Ingresa el nombre del usuario', isError: true);
      return;
    }
    if (libro.isEmpty && libroId == null) {
      _showSnackBar('Ingresa el libro o escanea el QR', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
      final tituloFinal = libro.isNotEmpty ? libro : libroTitulo;
      final idFinal = libroId ?? libro;
      final claveUnica = '${userId}_$idFinal';

      await FirebaseFirestore.instance
          .collection('prestamos')
          .doc(claveUnica)
          .set({
            'usuarioId': userId,
            'usuarioNombre': usuario,
            'libroId': idFinal,
            'libroTitulo': tituloFinal.toLowerCase(),
            'fechaPrestamo': Timestamp.fromDate(fechaPrestamo),
            'fechaDevolucion': Timestamp.fromDate(fechaDevolucion),
            'estado': 'Prestado',
          }, SetOptions(merge: true));

      if (libroId != null) {
        await FirebaseFirestore.instance
            .collection('libros')
            .doc(libroId)
            .update({
              'estado': 'Prestado',
              'disponible': false,
              'vecesPresado': FieldValue.increment(1),
            });
      } else {
        final query = await FirebaseFirestore.instance
            .collection('libros')
            .where('titulo', isEqualTo: tituloFinal)
            .limit(1)
            .get();

        final query2 = query.docs.isEmpty
            ? await FirebaseFirestore.instance
                  .collection('libros')
                  .where('titulo', isEqualTo: tituloFinal.toLowerCase())
                  .limit(1)
                  .get()
            : null;

        final doc = query.docs.isNotEmpty
            ? query.docs.first
            : query2?.docs.isNotEmpty == true
            ? query2!.docs.first
            : null;

        if (doc != null) {
          await doc.reference.update({
            'estado': 'Prestado',
            'disponible': false,
            'vecesPresado': FieldValue.increment(1),
          });
        }
      }

      try {
        await programarRecordatorio(fechaDevolucion, tituloFinal);
      } catch (e) {
        debugPrint('Error programando notificación: $e');
      }

      _showSnackBar('Préstamo registrado correctamente');

      _usuarioController.clear();
      _libroController.clear();
      setState(() {
        libroId = null;
        libroTitulo = '';
        fechaPrestamo = DateTime.now();
        fechaDevolucion = DateTime.now().add(const Duration(days: 7));
      });
    } catch (e) {
      _showSnackBar('Error al registrar el préstamo', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarDevolucion() async {
    final libro = _libroController.text.trim();
    if (libro.isEmpty && libroId == null) {
      _showSnackBar('Escanea un libro o ingresa el nombre', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonimo';
      final idFinal = libroId ?? libro;
      final claveUnica = '${userId}_$idFinal';

      await FirebaseFirestore.instance
          .collection('prestamos')
          .doc(claveUnica)
          .update({'estado': 'Devuelto'});

      if (libroId != null) {
        await FirebaseFirestore.instance
            .collection('libros')
            .doc(libroId)
            .update({'estado': 'Disponible', 'disponible': true});
      } else {
        final tituloLibro = _libroController.text.trim();
        final query = await FirebaseFirestore.instance
            .collection('libros')
            .where('titulo', isEqualTo: tituloLibro)
            .limit(1)
            .get();

        final query2 = query.docs.isEmpty
            ? await FirebaseFirestore.instance
                  .collection('libros')
                  .where('titulo', isEqualTo: tituloLibro.toLowerCase())
                  .limit(1)
                  .get()
            : null;

        final doc = query.docs.isNotEmpty
            ? query.docs.first
            : query2?.docs.isNotEmpty == true
            ? query2!.docs.first
            : null;

        if (doc != null) {
          await doc.reference.update({
            'estado': 'Disponible',
            'disponible': true,
          });
        }
      }

      _showSnackBar('Libro devuelto y estado actualizado');

      _usuarioController.clear();
      _libroController.clear();
      setState(() {
        libroId = null;
        libroTitulo = '';
      });
    } catch (e) {
      _showSnackBar('Error al registrar devolución', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFC62828)
            : const Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isDevolucion) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDevolucion ? fechaDevolucion : fechaPrestamo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDevolucion) {
          fechaDevolucion = picked;
        } else {
          fechaPrestamo = picked;
        }
      });
    }
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _libroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: const Text(
          'Nuevo préstamo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _scanQR(context),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: libroId != null
                          ? const Color(0xFF1565C0)
                          : const Color(0xFFBBDEFB),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        // ✅ withValues en lugar de withOpacity
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: libroId != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF1565C0),
                              size: 44,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'QR escaneado',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                libroId!.length > 16
                                    ? '${libroId!.substring(0, 16)}...'
                                    : libroId!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Toca para escanear',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'O completa los datos manualmente',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    // ✅ withValues en lugar de withOpacity
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField(
                    controller: _usuarioController,
                    icon: Icons.person_outline,
                    label: 'Usuario',
                    hint: 'Nombre del usuario',
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    controller: _libroController,
                    icon: Icons.menu_book_outlined,
                    label: 'Libro',
                    hint: 'Título del libro',
                    suffix: libroId != null
                        ? const Icon(
                            Icons.qr_code,
                            color: Color(0xFF1565C0),
                            size: 20,
                          )
                        : null,
                  ),
                  const Divider(height: 28),
                  _dateRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha de préstamo',
                    value: _formatFecha(fechaPrestamo),
                    onTap: () => _selectDate(context, false),
                  ),
                  const Divider(height: 28),
                  _dateRow(
                    icon: Icons.event_outlined,
                    label: 'Fecha de devolución',
                    value: _formatFecha(fechaDevolucion),
                    onTap: () => _selectDate(context, true),
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registrarPrestamo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Confirmar Préstamo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _registrarDevolucion,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Registrar devolución',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 22),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _dateRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: highlight
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.edit_calendar_outlined,
            color: Colors.grey,
            size: 18,
          ),
        ],
      ),
    );
  }
}

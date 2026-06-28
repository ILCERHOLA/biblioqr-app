import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/libro_card.dart';
import '../menu/my_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filtro = 'Todos';
  String _busqueda = '';
  final _searchController = TextEditingController();

  final List<String> _filtros = [
    'Todos',
    'Disponibles',
    'Prestados',
    'Vencidos',
  ];

  bool _coincideFiltro(String estado) {
    if (_filtro == 'Todos') return true;
    if (_filtro == 'Disponibles') return estado.toLowerCase() == 'disponible';
    if (_filtro == 'Prestados') return estado.toLowerCase() == 'prestado';
    if (_filtro == 'Vencidos') return estado.toLowerCase() == 'vencido';
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      drawer: const MyDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/BiblioQR.png', width: 32, height: 32),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Biblio',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  TextSpan(
                    text: 'QR',
                    style: TextStyle(
                      color: Color(0xFF64B5F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/recordatorio'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header azul con buscador y filtros
          Container(
            color: const Color(0xFF1565C0),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        // ✅ withValues en lugar de withOpacity
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _busqueda = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Buscar libro...',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF1565C0),
                      ),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _busqueda = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filtros.map((f) {
                      final selected = _filtro == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filtro = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? Colors.white : Colors.white38,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF1565C0)
                                    : Colors.white,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Título + botones
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Libros populares',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/prestamo'),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text(
                        'Escanear QR',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/addBook'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista desde Firestore usando LibroCard
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('libros')
                  .orderBy('vecesPresado', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('libros')
                        .orderBy('titulo')
                        .snapshots(),
                    builder: (context, snapshot2) {
                      if (snapshot2.hasError) {
                        return const Center(
                          child: Text('Error al cargar libros'),
                        );
                      }
                      if (snapshot2.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1565C0),
                          ),
                        );
                      }
                      return _buildLista(snapshot2.data!.docs);
                    },
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                  );
                }
                return _buildLista(snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<QueryDocumentSnapshot> todos) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay libros registrados',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final libros = todos.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final titulo = (data['titulo'] ?? '').toString().toLowerCase();
      final autor = (data['autor'] ?? '').toString().toLowerCase();
      final estado = (data['estado'] ?? '').toString();
      return (titulo.contains(_busqueda) || autor.contains(_busqueda)) &&
          _coincideFiltro(estado);
    }).toList();

    if (libros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin resultados',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: libros.length,
      itemBuilder: (context, i) {
        final data = libros[i].data() as Map<String, dynamic>;
        return LibroCard(
          titulo: data['titulo'] ?? 'Sin título',
          autor: data['autor'] ?? 'Autor desconocido',
          estado: data['estado'] ?? 'disponible',
          portadaUrl: data['portadaUrl'],
          vecesPresado: data['vecesPresado'] ?? 0,
        );
      },
    );
  }
}

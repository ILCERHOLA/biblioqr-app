import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _autorController = TextEditingController();
  bool _disponible = true;

  Future<void> _guardarLibro() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('libros').add({
        'titulo': _tituloController.text,
        'autor': _autorController.text,
        'disponible': _disponible,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Libro agregado correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Libro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el título' : null,
              ),
              TextFormField(
                controller: _autorController,
                decoration: const InputDecoration(labelText: 'Autor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el autor' : null,
              ),
              SwitchListTile(
                title: const Text('Disponible'),
                value: _disponible,
                onChanged: (value) => setState(() => _disponible = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarLibro,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

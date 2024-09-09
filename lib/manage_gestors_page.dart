import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageGestorsPage extends StatefulWidget {
  final String institutionId;

  const ManageGestorsPage({Key? key, required this.institutionId})
      : super(key: key);

  @override
  _ManageGestorsPageState createState() => _ManageGestorsPageState();
}

class _ManageGestorsPageState extends State<ManageGestorsPage> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _gestors = [];

  @override
  void initState() {
    super.initState();
    _fetchGestors(); // Cargar gestores al inicio
  }

  Future<void> _fetchGestors() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('usuarios')
        .where('id_institucion', isEqualTo: widget.institutionId)
        .where('rol', isEqualTo: 'gestor')
        .get();

    setState(() {
      // Incluye el ID del documento para poder eliminarlo
      _gestors = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Añade el ID del documento
        return data;
      }).toList();
    });
  }

  Future<void> _addGestor() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    QuerySnapshot userQuery = await _firestore
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isNotEmpty) {
      final userData = userQuery.docs.first.data() as Map<String, dynamic>;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Hacer gestor"),
          content: Text(
              "¿Hacer gestor a ${userData['nombre']} ${userData['apellido']}?"),
          actions: [
            TextButton(
              onPressed: () async {
                await _firestore
                    .collection('usuarios')
                    .doc(userQuery.docs.first.id)
                    .update({
                  'rol': 'gestor',
                  'id_institucion': widget.institutionId,
                });
                Navigator.pop(context);
                _fetchGestors(); // Recargar la lista de gestores
              },
              child: Text("Sí"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("No"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario no encontrado.")),
      );
    }
  }

  Future<void> _removeGestor(String gestorId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar gestor"),
        content: Text("¿Estás seguro de que deseas eliminar a este gestor?"),
        actions: [
          TextButton(
            onPressed: () async {
              await _firestore.collection('usuarios').doc(gestorId).update({
                'rol': null,
                'id_institucion': null,
              });
              Navigator.pop(context);
              _fetchGestors(); // Recargar la lista de gestores
            },
            child: Text("Sí"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Gestores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo del nuevo gestor',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addGestor,
            child: Text('Agregar Gestor'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _gestors.length,
              itemBuilder: (context, index) {
                final gestor = _gestors[index];
                return ListTile(
                  title: Text('${gestor['nombre']} ${gestor['apellido']}'),
                  subtitle: Text('Correo: ${gestor['email']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeGestor(gestor['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

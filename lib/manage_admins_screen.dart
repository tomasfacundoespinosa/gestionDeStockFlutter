import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageAdminsScreen extends StatefulWidget {
  @override
  _ManageAdminsScreenState createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _institutionNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); // Controlador para la contraseña de confirmación
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addAdministrator() async {
    final dni = _dniController.text.trim();
    final institutionName = _institutionNameController.text.trim();

    if (dni.isEmpty || institutionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, ingrese el DNI del usuario y el nombre de la institución.')));
      return;
    }

    var userQuery = await _firestore.collection('usuarios').where('dni', isEqualTo: dni).get();
    var institutionQuery = await _firestore.collection('instituciones').where('name', isEqualTo: institutionName).get();

    if (userQuery.docs.isNotEmpty && institutionQuery.docs.isNotEmpty) {
      final userData = userQuery.docs.first.data();
      final institutionId = institutionQuery.docs.first.id;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Hacer administrador"),
          content: Text("¿Hacer administrador a ${userData['nombre']} ${userData['apellido']} en ${institutionName}?"),
          actions: [
            TextButton(
              onPressed: () async {
                await _firestore.collection('usuarios').doc(userQuery.docs.first.id).update({
                  'rol': 'admin',
                  'id_institucion': institutionId
                });
                Navigator.of(context).pop();
              },
              child: Text("Sí"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Usuario o institución no encontrados.")),
      );
    }
  }

  void _deleteAdministrator(String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: "Contraseña de confirmación"),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () async {
                try {
                  // Reautenticar usuario
                  User? user = _auth.currentUser;
                  String email = user!.email!;
                  AuthCredential credential = EmailAuthProvider.credential(email: email, password: _passwordController.text);
                  await user.reauthenticateWithCredential(credential);
                  await _firestore.collection('usuarios').doc(userId).update({'rol': null, 'id_institucion': null});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Administrador eliminado correctamente.")));
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de autenticación.")));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Administradores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _dniController,
              decoration: InputDecoration(labelText: 'DNI del Usuario'),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _institutionNameController,
              decoration: InputDecoration(labelText: 'Nombre de la Institución'),
            ),
          ),
          ElevatedButton(
            onPressed: _addAdministrator,
            child: Text('Agregar Administrador'),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('usuarios').where('rol', isEqualTo: 'admin').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var adminData = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('${adminData['nombre']} ${adminData['apellido']}'),
                      subtitle: Text('DNI: ${adminData['dni']} - Institución: ${adminData['id_institucion']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteAdministrator(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

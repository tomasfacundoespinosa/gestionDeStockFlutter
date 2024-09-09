import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_admins_screen.dart'; // Importa la pantalla de gestionar admins

class Institution {
  final String id;
  final String name;
  final String address;
  final String phone;

  Institution({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory Institution.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Institution(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }
}

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  void addInstitution() {
    final name = nameController.text;
    final address = addressController.text;
    final phone = phoneController.text;

    if (name.isNotEmpty && address.isNotEmpty && phone.isNotEmpty) {
      FirebaseFirestore.instance.collection('instituciones').add({
        'name': name,
        'address': address,
        'phone': phone,
      });
      nameController.clear();
      addressController.clear();
      phoneController.clear();
    }
  }

  void deleteInstitution(String id) {
    FirebaseFirestore.instance.collection('instituciones').doc(id).delete();
  }

  void editInstitution(BuildContext context, Institution institution) async {
    final _formKey = GlobalKey<FormState>();
    String name = institution.name;
    String address = institution.address;
    String phone = institution.phone;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Institución'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre de la institución.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Nombre de la Institución',
                    ),
                    onChanged: (value) => name = value,
                  ),
                  TextFormField(
                    initialValue: address,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el domicilio.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Domicilio',
                    ),
                    onChanged: (value) => address = value,
                  ),
                  TextFormField(
                    initialValue: phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el teléfono.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Teléfono',
                    ),
                    onChanged: (value) => phone = value,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  FirebaseFirestore.instance.collection('instituciones').doc(institution.id).update({
                    'name': name,
                    'address': address,
                    'phone': phone,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
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
        title: Text('Pantalla de Administradores'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              // Navegar a la pantalla de gestión de administradores
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageAdminsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Domicilio'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Teléfono'),
            ),
          ),
          ElevatedButton(
            onPressed: addInstitution,
            child: Text('Agregar Institución'),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('instituciones').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var institution = Institution.fromFirestore(doc);
                    return ListTile(
                      title: Text(institution.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Domicilio: ${institution.address}'),
                          Text('Teléfono: ${institution.phone}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.person),
                            onPressed: () {
                              // Lógica para gestionar admins
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => editInstitution(context, institution),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deleteInstitution(institution.id),
                          ),
                        ],
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

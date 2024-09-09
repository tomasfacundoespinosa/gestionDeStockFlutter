import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'manage_gestors_page.dart'; // Importa la página para gestionar gestores

class MyHomePage extends StatefulWidget {
  final String title;
  final String institutionId; // ID de la Institución a la que pertenece el administrador
  final String userRole;

  const MyHomePage({Key? key, required this.title, required this.institutionId, required this.userRole})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  late List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _fetchProductos(); // Cargar productos de la institución al inicio
  }

  Future<void> _fetchProductos() async {
    // Obtener los productos filtrados por la institución del administrador
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('productos')
        .where('id_institucion', isEqualTo: widget.institutionId) // Filtrar por institución
        .get();

    setState(() {
      _productos = querySnapshot.docs
          .map((doc) => Producto.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: Column(
        children: [
          // Botón "Administrar Gestores" (Se añade en la parte superior)
          if (widget.userRole == 'admin') // Mostrar solo si el rol es 'admin'
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      onPressed: () {
        // Redirigir a la página de gestión de gestores
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManageGestorsPage(
              institutionId: widget.institutionId,
            ),
          ),
        );
      },
      child: Text('Administrar Gestores'),
    ),
  ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o categoría',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {}); // Actualizar la interfaz al cambiar el texto de búsqueda
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final producto = _productos[index];
                // Filtrar productos por nombre y categoría
                final bool matchesSearch = producto.nombre
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase()) ||
                    producto.categoria
                        .toLowerCase()
                        .contains(_searchController.text.toLowerCase());
                if (!matchesSearch) {
                  return Container(); // Si no hay coincidencias, no mostrar este elemento
                }
                return ListTile(
                  title: Text(producto.nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio: \$${producto.precio.toStringAsFixed(2)}'),
                      Text('Cantidad: ${producto.cantidad}'),
                      Text('Categoría: ${producto.categoria}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _eliminarProducto(index),
                  ),
                  onTap: () => _editarProducto(context, index),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _agregarProducto(context),
        label: const Text('Agregar Producto'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Navega al login
      );
    } catch (e) {
      print('Error cerrando sesión: $e');
    }
  }

  Future<void> _agregarProducto(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String nombreProducto = "";
    double precioProducto = 0.0;
    int cantidadProducto = 0;
    String categoriaProducto = "";

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del producto.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(hintText: 'Nombre del Producto'),
                    onChanged: (value) => nombreProducto = value,
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el precio del producto.';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Precio del Producto'),
                    onChanged: (value) => precioProducto = double.parse(value),
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la cantidad inicial.';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Cantidad Inicial'),
                    onChanged: (value) => cantidadProducto = int.parse(value),
                  ),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la categoría del producto.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(hintText: 'Categoría del Producto'),
                    onChanged: (value) => categoriaProducto = value,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('productos').add({
                    'nombre': nombreProducto,
                    'precio': precioProducto,
                    'cantidad': cantidadProducto,
                    'categoria': categoriaProducto,
                    'id_institucion': widget.institutionId,
                  });

                  Navigator.pop(context);
                  _fetchProductos();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarProducto(int index) async {
    await FirebaseFirestore.instance.collection('productos').doc(_productos[index].id).delete();
    setState(() {
      _productos.removeAt(index);
    });
  }

  void _editarProducto(BuildContext context, int index) async {
    final _formKey = GlobalKey<FormState>();
    String nombreProducto = _productos[index].nombre;
    double precioProducto = _productos[index].precio;
    int cantidadProducto = _productos[index].cantidad;
    String categoriaProducto = _productos[index].categoria;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Producto'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    initialValue: nombreProducto,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el nombre del producto.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(hintText: 'Nombre del Producto'),
                    onChanged: (value) => nombreProducto = value,
                  ),
                  TextFormField(
                    initialValue: precioProducto.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese el precio del producto.';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Precio del Producto'),
                    onChanged: (value) => precioProducto = double.parse(value),
                  ),
                  TextFormField(
                    initialValue: cantidadProducto.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la cantidad inicial.';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Cantidad Inicial'),
                    onChanged: (value) => cantidadProducto = int.parse(value),
                  ),
                  TextFormField(
                    initialValue: categoriaProducto,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese la categoría del producto.';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(hintText: 'Categoría del Producto'),
                    onChanged: (value) => categoriaProducto = value,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('productos').doc(_productos[index].id).update({
                    'nombre': nombreProducto,
                    'precio': precioProducto,
                    'cantidad': cantidadProducto,
                    'categoria': categoriaProducto,
                  });

                  Navigator.pop(context);
                  _fetchProductos();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

class Producto {
  final String id;
  final String nombre;
  double precio;
  int cantidad;
  final String categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  factory Producto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Producto(
      id: doc.id,
      nombre: data['nombre'],
      precio: data['precio'],
      cantidad: data['cantidad'],
      categoria: data['categoria'],
    );
  }
}

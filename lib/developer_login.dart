import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen.dart'; // Importa la pantalla de administradores

class DeveloperLoginPage extends StatefulWidget {
  @override
  _DeveloperLoginPageState createState() => _DeveloperLoginPageState();
}

class _DeveloperLoginPageState extends State<DeveloperLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login de Desarrolladores'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(16.0),
          constraints:
              BoxConstraints(maxWidth: 400), // Limita el ancho del contenedor
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Login de Desarrolladores',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    icon: Icon(Icons.email),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Contraseña',
                    border: InputBorder.none,
                    icon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  String email = _emailController.text.trim();
                  String password = _passwordController.text.trim();
                  try {
                    UserCredential userCredential =
                        await _auth.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                    // Obtener el UID del usuario actual
                    String uid = userCredential.user!.uid;

                    // Verificar si existe un documento en la colección 'desarrolladores' con el UID actual
                    DocumentSnapshot developerDoc = await FirebaseFirestore
                        .instance
                        .collection('desarrolladores')
                        .doc(uid)
                        .get();

                    if (developerDoc.exists) {
                      // Verificar el rol del desarrollador
                      String rol = developerDoc['rol'];

                      if (rol == 'desarrollador') {
                        // Redirigir a la pantalla de administradores
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminScreen(),
                          ),
                        );
                      } else {
                        setState(() {
                          _errorMessage =
                              'Usuario no autorizado como desarrollador';
                        });
                      }
                    } else {
                      setState(() {
                        _errorMessage =
                            'Usuario no encontrado en la colección de desarrolladores';
                      });
                    }
                  } catch (e) {
                    _showErrorSnackbar(
                        'Error al iniciar sesión como desarrollador: $e');
                    print('Error logging in as developer: $e');
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 16.0),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

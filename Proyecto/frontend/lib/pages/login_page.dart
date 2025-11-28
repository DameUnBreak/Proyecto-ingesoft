import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final api = ApiService();
  String mensaje = '';

  Future<void> login() async {
    final correo = _correoCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      setState(() {
        mensaje = 'Por favor ingresa correo y contraseña.';
      });
      return;
    }

    try {
      final resultado = await api.login(correo, contrasena);

      if (resultado['status'] == 200) {
        // Navegar al Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(correo: correo),
          ),
        );
      } else {
        setState(() {
          mensaje = '❌ ${resultado['body']['error'] ?? "Error en login"}';
        });
      }
    } catch (e) {
      setState(() {
        mensaje = 'Error de conexión con el servidor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // OJO: NADA aquí está marcado como const arriba del todo,
    // solo los Text o iconos sueltos que sí son constantes.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login SmartCar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _correoCtrl,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: _contrasenaCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Ingresar'),
            ),
            const SizedBox(height: 10),
            Text(mensaje),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // IMPORTANTE: nada de const aquí
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                );
              },
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

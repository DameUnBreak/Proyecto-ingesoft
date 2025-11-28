import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final api = ApiService();
  String mensaje = '';
  bool _isLoading = false;

  Future<void> registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (nombre.isEmpty || correo.isEmpty || contrasena.isEmpty) {
      setState(() {
        mensaje = 'Por favor completa todos los campos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      mensaje = '';
    });

    try {
      final resultado = await api.registerUser(nombre, correo, contrasena);

      if (resultado['status'] == 201) {
        setState(() {
          mensaje = '✅ Usuario creado. Ahora inicia sesión.';
        });
        // Optional: Navigate back to login after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() {
          mensaje = '❌ Error: ${resultado['body']}';
        });
      }
    } catch (e) {
      setState(() {
        mensaje = 'Error de conexión: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.person_add_rounded,
                size: 64,
                color: Color(0xFF2E7D32),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _correoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contrasenaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : registrar,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('REGISTRARSE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (mensaje.isNotEmpty)
                Text(
                  mensaje,
                  style: TextStyle(
                    color: mensaje.startsWith('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

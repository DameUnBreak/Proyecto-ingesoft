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
  bool _isLoading = false;

  Future<void> login() async {
    final correo = _correoCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (correo.isEmpty || contrasena.isEmpty) {
      setState(() {
        mensaje = 'Por favor ingresa correo y contraseña.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      mensaje = '';
    });

    try {
      final resultado = await api.login(correo, contrasena);

      if (resultado['status'] == 200) {
        final body = resultado['body'];
        final int userId = body['id'];
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(correo: correo, userId: userId),
          ),
        );
      } else {
        setState(() {
          final body = resultado['body'];
          final errorMsg =
              body is Map && body['error'] != null ? body['error'] : 'Error en login';
          mensaje = '❌ $errorMsg';
        });
      }
    } catch (e) {
      setState(() {
        mensaje = 'Error de conexión con el servidor.';
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
  void dispose() {
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SmartCar',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organiza tus listas de compras y presupuesto',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _correoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contrasenaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('INGRESAR'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (mensaje.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        mensaje,
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      );
                    },
                    child:
                        const Text('¿No tienes cuenta? Regístrate aquí'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

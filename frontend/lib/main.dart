import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const SmartCarApp());

class SmartCarApp extends StatelessWidget {
  const SmartCarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCar Hola Mundo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HolaMundoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HolaMundoScreen extends StatefulWidget {
  const HolaMundoScreen({super.key});
  @override
  State<HolaMundoScreen> createState() => _HolaMundoScreenState();
}

class _HolaMundoScreenState extends State<HolaMundoScreen> {
  String mensaje = "Presiona el botón para saludar 👋";
  bool cargando = false;

  Future<void> obtenerHolaMundo() async {
    setState(() => cargando = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/hola_mundo'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => mensaje = data['mensaje'] ?? 'Sin mensaje');
      } else {
        setState(() => mensaje = "Error del servidor: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => mensaje = "❌ No se pudo conectar al backend");
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartCar - Hola Mundo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: Text(cargando ? "Cargando..." : "Obtener mensaje"),
                onPressed: cargando ? null : obtenerHolaMundo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

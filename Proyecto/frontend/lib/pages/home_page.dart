import 'package:flutter/material.dart';
import 'mis_listas_page.dart';

class HomePage extends StatelessWidget {
  final String correo;

  const HomePage({super.key, required this.correo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartCar - Inicio'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MisListasPage(),
              ),
            );
          },
          child: const Text('Ir a Mis Listas'),
        ),
      ),
    );
  }
}

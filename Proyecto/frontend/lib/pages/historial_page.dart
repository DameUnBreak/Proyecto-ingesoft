import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistorialPage extends StatefulWidget {
  final int usuarioId;

  const HistorialPage({super.key, required this.usuarioId});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final ApiService api = ApiService();
  List historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    final res = await api.obtenerHistorial(widget.usuarioId);

    if (res["status"] == 200) {
      setState(() {
        historial = res["body"]["historial"];
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: historial.length,
              itemBuilder: (context, index) {
                final h = historial[index];
                return Card(
                  child: ListTile(
                    title: Text("Mes: ${h["mes"]}"),
                    subtitle: Text(
                      "Total: ${h["total"]}\nItems: ${h["numero_items"]}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}

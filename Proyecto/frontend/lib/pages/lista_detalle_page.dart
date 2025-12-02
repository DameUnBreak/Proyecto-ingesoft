import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ListaDetallePage extends StatefulWidget {
  final int listaId;
  final String nombreLista;

  const ListaDetallePage({
    super.key,
    required this.listaId,
    required this.nombreLista,
  });

  @override
  State<ListaDetallePage> createState() => _ListaDetallePageState();
}

class _ListaDetallePageState extends State<ListaDetallePage> {
  final ApiService api = ApiService();

  List<dynamic> items = [];
  bool cargando = false;
  String? error;

  Map<String, dynamic>? resumen;
  List<String> recomendaciones = [];

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController categoriaController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController precioController = TextEditingController();

  final NumberFormat _copFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  String _formatCurrency(dynamic value) {
    if (value == null) return '-';
    final numValue = double.tryParse(value.toString()) ?? 0;
    return _copFormat.format(numValue);
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadResumenYRecomendaciones();
  }

  Future<void> _loadItems() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final data = await api.getItems(widget.listaId);
      setState(() {
        items = data;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando ítems: $e';
      });
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _loadResumenYRecomendaciones() async {
    try {
      final r = await api.getResumenLista(widget.listaId);
      final recs = await api.getRecomendaciones(widget.listaId);

      setState(() {
        resumen = r;
        recomendaciones = recs;
      });
    } catch (_) {}
  }

  Future<void> _crearItem() async {
    final nombre = nombreController.text.trim();
    final categoria = categoriaController.text.trim();
    final cantidadText = cantidadController.text.trim();
    final precioText = precioController.text.trim();

    if (nombre.isEmpty || cantidadText.isEmpty || precioText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre, cantidad y precio son obligatorios'),
        ),
      );
      return;
    }

    final cantidad = int.tryParse(cantidadText);
    final precio = double.tryParse(precioText);

    if (cantidad == null || precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cantidad o precio no tienen un formato válido'),
        ),
      );
      return;
    }

    try {
      final ok = await api.crearItem(
        widget.listaId,
        nombre,
        cantidad,
        categoria,
        precio,
      );

      if (ok) {
        nombreController.clear();
        categoriaController.clear();
        cantidadController.clear();
        precioController.clear();
        _loadItems();
        _loadResumenYRecomendaciones();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el ítem')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el ítem: $e')),
      );
    }
  }

  void _mostrarDialogoCrearItem() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar ítem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: precioController,
              decoration: const InputDecoration(labelText: 'Precio unitario'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _crearItem();
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    if (resumen == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Presupuesto: ${_formatCurrency(resumen!['presupuesto'])}",
            ),
            Text(
              "Total calculado: ${_formatCurrency(resumen!['total'])}",
            ),
            if (resumen!['supera_presupuesto'])
              const Text(
                "⚠️ ¡Se supera el presupuesto!",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendaciones() {
    if (recomendaciones.isEmpty) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recomendaciones:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recomendaciones.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("- $r"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreLista),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearItem,
        child: const Icon(Icons.add),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    _buildResumen(),
                    _buildRecomendaciones(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          final nombre = (item['nombre'] ?? '').toString();
                          final cantidad = item['cantidad'];
                          final precio = item['precio_unitario'];

                          return ListTile(
                            title: Text(nombre),
                            subtitle: Text(
                              "Cantidad: $cantidad - Precio: ${_formatCurrency(precio)}",
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
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

  late Future<List<dynamic>> _itemsFuture;
  bool _cargando = false;
  Map<String, dynamic>? resumen;
  bool cargandoResumen = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    cargarResumen();
  }

  void cargarResumen() async {
  resumen = await api.getResumenLista(widget.listaId);
  cargandoResumen = false;
  setState(() {});
}

  void _cargarDatos() {
    _itemsFuture = api.getItems(widget.listaId);
    setState(() {});
  }


  Future <void>  _mostrarRecomendaciones() async {
  final recomendaciones = await api.getRecomendaciones(widget.listaId);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "Recomendaciones",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recomendaciones.isNotEmpty
                    ? recomendaciones.join("\n• ")
                    : "No hay recomendaciones",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            // ❌ Botón cerrar (X)
            Positioned(
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}

 
  /// CREAR ITEM
 
  Future<void> _crearItem() async {
    final nombreController = TextEditingController();
    final categoriaController = TextEditingController();
    final cantidadController = TextEditingController();
    final precioController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final categoria = categoriaController.text.trim();
                final int? cantidad = int.tryParse(cantidadController.text.trim());
                final double? precio =
                    double.tryParse(precioController.text.trim());

                if (nombre.isEmpty ||
                    categoria.isEmpty ||
                    cantidad == null ||
                    precio == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completa todos los campos")),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _cargando = true);

                try {
                  final ok = await api.crearItem(
                    widget.listaId,
                    nombre,
                    categoria,
                    cantidad,
                    precio,
                  );

                  if (ok) {
                    _cargarDatos();
                    cargarResumen();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No se pudo crear el ítem")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                } finally {
                  if (mounted) setState(() => _cargando = false);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// ================================
  /// EDITAR ITEM
  /// ================================
  Future<void> _editarItem(Map item) async {
    final nombreController = TextEditingController(text: item["nombre"]);
    final categoriaController = TextEditingController(text: item["categoria"]);
    final cantidadController =
        TextEditingController();
    final precioController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Editar ítem"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: categoriaController,
                decoration: const InputDecoration(labelText: "Categoría"),
              ),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(labelText: "Cantidad"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: precioController,
                decoration:
                    const InputDecoration(labelText: "Precio unitario"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = nombreController.text.trim();
                final categoria = categoriaController.text.trim();
                final int? cantidad =
                    int.tryParse(cantidadController.text.trim());
                final double? precio =
                    double.tryParse(precioController.text.trim());

                if (nombre.isEmpty ||
                    categoria.isEmpty ||
                    cantidad == null ||
                    precio == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completa todos los campos")),
                  );
                  return;
                }

                Navigator.pop(context);
                setState(() => _cargando = true);

                final ok = await api.editarItem(
                  item["id"],
                  nombre,
                  categoria,
                  cantidad,
                  precio,
                );

                if (ok) {
                  _cargarDatos();
                  cargarResumen();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No se pudo actualizar")),
                  );
                }

                if (mounted) setState(() => _cargando = false);
              },
              child: const Text("Guardar cambios"),
            ),
          ],
        );
      },
    );
  }

  /// ================================
  /// BORRAR ITEM
  /// ================================
  Future<void> _borrarItem(int id) async {
    setState(() => _cargando = true);

    try {
      final ok = await api.borrarItem(id);

      if (!mounted) return;

      if (ok) {
        _cargarDatos();
        cargarResumen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo eliminar")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión: $e")),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// ================================
  /// UI
  /// ================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreLista),
      ),
      body: Column(
        children: [
          cargandoResumen
        ? const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        : resumen == null
            ? const SizedBox.shrink()
            : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: resumen!["supera_presupuesto"]
              ? Colors.red.withOpacity(0.2)
              : resumen!["total"] >= resumen!["presupuesto"] * 0.5
              ? Colors.orange.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Presupuesto: \$${resumen!["presupuesto"].toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Total: \$${resumen!["total"].toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (resumen!["supera_presupuesto"])
                  const Text(
                    "⚠️ Has superado el presupuesto",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!resumen!["supera_presupuesto"] &&
                  resumen!["total"] >= resumen!["presupuesto"] * 0.5)
                  const Text(
                    "⚠️ Has excedido el 50% del presupuesto",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder(
              future: _itemsFuture,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snap.data!;

                if (items.isEmpty) {
                  return const Center(
                    child: Text("No hay ítems en esta lista."),
                  );
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(item["nombre"] ?? ""),
                      subtitle: Text(
                        "Categoría: ${item["categoria"]}\n"
                        "Precio: \$${item["precio_unitario"]} - Cant: ${item["cantidad"]}",
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: _cargando
                                ? null
                                : () => _editarItem(item),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.delete, color: Colors.red),
                            onPressed: _cargando
                                ? null
                                : () => _borrarItem(item["id"]),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: _mostrarRecomendaciones,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text(
                "Recomendaciones",
                style: TextStyle(fontSize: 16),
              )
            )  
          )    
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _cargando ? null : _crearItem,
        child: _cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
      ),
    ) ;
  }
}

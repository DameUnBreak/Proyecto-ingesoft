import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'crear_lista_page.dart';
import 'lista_detalle_page.dart';




class MisListasPage extends StatefulWidget {
  const MisListasPage({super.key});

  @override
  State<MisListasPage> createState() => _MisListasPageState();
}

class _MisListasPageState extends State<MisListasPage> {
  final ApiService api = ApiService();

  List<dynamic> _listas = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadListas();
  }

  Future<void> _loadListas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await api.getListas();
      // ignore: avoid_print
      print('DEBUG listas: $data');

      setState(() {
        _listas = data;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando listas: $e';
      });
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _abrirCrearLista() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CrearListaPage(),
      ),
    );

    if (creado == true) {
      _loadListas();
    }
  }

  Future<void> _abrirEditarLista(Map<String, dynamic> lista) async {
    final editado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearListaPage(listaInicial: lista),
      ),
    );

    if (editado == true) {
      _loadListas();
    }
  }

  Future<void> _eliminarLista(int id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lista'),
        content: const Text(
          '¿Seguro que quieres eliminar esta lista? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      final ok = await api.eliminarLista(id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista eliminada')),
        );
        _loadListas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la lista')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la lista: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis listas'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirCrearLista,
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadListas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_listas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_add, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes listas',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea una nueva con el botón +',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _listas.length,
      itemBuilder: (context, index) {
        final dynamic raw = _listas[index];
        final Map<String, dynamic> lista =
            raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);

        final String nombre = (lista['nombre'] ?? 'Sin nombre').toString();

        final int? id = () {
          final rawId = lista['id'];
          if (rawId == null) return null;
          if (rawId is int) return rawId;
          return int.tryParse(rawId.toString());
        }();

        final double? presupuesto = lista['presupuesto'] != null
            ? double.tryParse(lista['presupuesto'].toString())
            : null;

        final double? totalCalculado = lista['total_calculado'] != null
            ? double.tryParse(lista['total_calculado'].toString())
            : null;

        final double? totalMostrado = totalCalculado ?? presupuesto;

        String subtitulo;
        if (presupuesto == null && totalMostrado == null) {
          subtitulo = 'Sin presupuesto';
        } else {
          subtitulo =
              'Total: \$${totalMostrado?.toStringAsFixed(2) ?? "0.00"}';
          if (presupuesto != null) {
            subtitulo += ' / \$${presupuesto.toStringAsFixed(2)}';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.shopping_cart_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitulo),
            ),
            onTap: () {
              if (id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListaDetallePage(
                      listaId: id,
                      nombreLista: nombre,
                    ),
                  )
                );
              }
            },
            trailing: id == null
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _abrirEditarLista(lista);
                      } else if (value == 'delete') {
                        _eliminarLista(id);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

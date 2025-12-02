import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'crear_lista_page.dart';
import 'lista_detalle_page.dart';

class MisListasPage extends StatefulWidget {
  final int usuarioId;

  const MisListasPage({super.key, required this.usuarioId});

  @override
  State<MisListasPage> createState() => _MisListasPageState();
}

class _MisListasPageState extends State<MisListasPage> {
  final ApiService api = ApiService();

  List<dynamic> _listas = [];
  bool _cargando = false;
  String? _error;

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
    _loadListas();
  }

  Future<void> _loadListas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await api.getListas(widget.usuarioId);
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
        builder: (_) => CrearListaPage(usuarioId: widget.usuarioId),
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
        builder: (_) =>
            CrearListaPage(listaInicial: lista, usuarioId: widget.usuarioId),
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
          ElevatedButton(
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

  void _abrirDetalleLista(Map<String, dynamic> lista) {
    final id = lista['id'] as int?;
    final nombre = (lista['nombre'] ?? '').toString();

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de lista inválido')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListaDetallePage(listaId: id, nombreLista: nombre),
      ),
    );
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
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_listas.isEmpty) {
      return const Center(
        child: Text('Aún no tienes listas creadas.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadListas,
      child: ListView.builder(
        itemCount: _listas.length,
        itemBuilder: (context, index) {
          final lista = _listas[index] as Map<String, dynamic>;
          final nombre = (lista['nombre'] ?? '').toString();
          final presupuesto = lista['presupuesto'];
          final totalCalculado = lista['total_calculado'];

          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(nombre),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (presupuesto != null)
                    Text('Presupuesto: ${_formatCurrency(presupuesto)}'),
                  if (totalCalculado != null)
                    Text('Total: ${_formatCurrency(totalCalculado)}'),
                ],
              ),
              onTap: () => _abrirDetalleLista(lista),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _abrirEditarLista(lista);
                  } else if (value == 'eliminar') {
                    final id = lista['id'] as int?;
                    if (id != null) {
                      _eliminarLista(id);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

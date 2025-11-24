import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'crear_lista_page.dart';

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
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadListas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_listas.isEmpty) {
      return const Center(
        child: Text('Aún no tienes listas.\nCrea una con el botón +'),
      );
    }

    return ListView.builder(
      itemCount: _listas.length,
      itemBuilder: (context, index) {
        final dynamic raw = _listas[index];
        // nos aseguramos de tratarlo como Map
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

        // 👇 Si el backend aún no calcula total, usamos presupuesto como "total visible"
        final double? totalMostrado = totalCalculado ?? presupuesto;

        String subtitulo;
        if (presupuesto == null && totalMostrado == null) {
          subtitulo = 'Sin valores calculados';
        } else {
          subtitulo =
              'Total: ${totalMostrado ?? 0}  |  Presupuesto: ${presupuesto ?? 0}';
        }

        return ListTile(
          title: Text(nombre),
          subtitle: Text(subtitulo),
          onTap: () {
            if (id != null) {
              _abrirEditarLista(lista);
            }
          },
          trailing: id == null
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _abrirEditarLista(lista),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _eliminarLista(id),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

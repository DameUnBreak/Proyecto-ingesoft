import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrearListaPage extends StatefulWidget {
  /// Si [listaInicial] es null → creamos nueva.
  /// Si viene con datos → editamos esa lista.
  final Map<String, dynamic>? listaInicial;

  const CrearListaPage({super.key, this.listaInicial});

  @override
  State<CrearListaPage> createState() => _CrearListaPageState();
}

class _CrearListaPageState extends State<CrearListaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _presupuestoController = TextEditingController();
  bool _isLoading = false;

  final ApiService api = ApiService();

  bool get _esEdicion => widget.listaInicial != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final lista = widget.listaInicial!;
      _nombreController.text = (lista['nombre'] ?? '').toString();

      final presu = lista['presupuesto'];
      if (presu != null) {
        _presupuestoController.text = presu.toString();
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();

    double? presupuesto;
    final rawPresu = _presupuestoController.text.trim();
    if (rawPresu.isNotEmpty) {
      presupuesto = double.tryParse(rawPresu.replaceAll(',', '.'));
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool ok = false;

      if (_esEdicion) {
        // EDITAR
        final rawId = widget.listaInicial!['id'];
        final int? id = rawId is int ? rawId : int.tryParse('$rawId');

        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: ID de lista inválido')),
          );
          return;
        }

        ok = await api.actualizarLista(id, nombre, presupuesto);
      } else {
        // CREAR
        ok = await api.crearLista(nombre, presupuesto);
      }

      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? 'Error al actualizar la lista'
                  : 'Error al crear la lista',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
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
    _nombreController.dispose();
    _presupuestoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _esEdicion ? 'Editar lista' : 'Crear nueva lista';
    final textoBoton = _esEdicion ? 'Guardar cambios' : 'Guardar';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la lista',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _presupuestoController,
                decoration: const InputDecoration(
                  labelText: 'Presupuesto (opcional)',
                  hintText: 'Ej: 150000',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(textoBoton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

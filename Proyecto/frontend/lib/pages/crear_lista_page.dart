import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CrearListaPage extends StatefulWidget {
  /// Si [listaInicial] es null → creamos nueva.
  /// Si viene con datos → editamos esa lista.
  final Map<String, dynamic>? listaInicial;
  final int usuarioId;

  const CrearListaPage(
      {super.key, this.listaInicial, required this.usuarioId});

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

      final presupuesto = lista['presupuesto'];
      if (presupuesto != null) {
        _presupuestoController.text = presupuesto.toString();
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _presupuestoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final presupuestoText = _presupuestoController.text.trim();
    final presupuesto =
        presupuestoText.isEmpty ? null : double.tryParse(presupuestoText);

    setState(() {
      _isLoading = true;
    });

    try {
      bool ok = false;

      if (_esEdicion) {
        // EDITAR
        final lista = widget.listaInicial!;
        final id = lista['id'] as int?;

        if (id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: ID de lista inválido')),
          );
          return;
        }

        ok = await api.actualizarLista(id, nombre, presupuesto);
      } else {
        // CREAR
        ok =
            await api.crearLista(nombre, presupuesto, widget.usuarioId);
      }

      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion
                  ? 'No se pudo actualizar la lista'
                  : 'No se pudo crear la lista',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la lista: $e'),
        ),
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
  Widget build(BuildContext context) {
    final titulo = _esEdicion ? 'Editar Lista' : 'Crear Lista';
    final textoBoton = _esEdicion ? 'Guardar cambios' : 'Crear lista';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la lista',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un nombre';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _presupuestoController,
                decoration: const InputDecoration(
                  labelText: 'Presupuesto (opcional)',
                  prefixIcon: Icon(Icons.monetization_on),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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

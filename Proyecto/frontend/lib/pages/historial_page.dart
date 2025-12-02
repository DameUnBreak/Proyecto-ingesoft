import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _historial = [];

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    try {
      final data = await _apiService.getHistorialResumen();
      setState(() {
        _historial = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historial.isEmpty
              ? const Center(
                  child: Text(
                    'No hay historial de compras aún.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final mesData = _historial[index];
                      return _buildMesCard(mesData);
                    },
                  ),
                ),
    );
  }

  Widget _buildMesCard(Map<String, dynamic> mesData) {
    final String mesStr = mesData['mes']; // "2025-11"
    final double totalMes = (mesData['total_mes'] as num).toDouble();
    final List<dynamic> categorias = mesData['categorias'];

    // Formatear fecha para mostrar nombre del mes
    final parts = mesStr.split('-');
    final year = parts[0];
    final month = parts[1];
    
    // Mapa simple de meses
    final mesesNombres = {
      '01': 'Ene', '02': 'Feb', '03': 'Mar', '04': 'Abr',
      '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Ago',
      '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dic'
    };
    final mesNombre = mesesNombres[month] ?? month;

    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    // Colores para las categorías
    final List<Color> colores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          _mostrarDetallesMes(mesData);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Mes y Total
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mesNombre,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Total
              Text(
                'Gasto Total',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currencyFormat.format(totalMes),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Gráfico circular
              if (categorias.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 25,
                      sections: categorias.asMap().entries.map((entry) {
                        final index = entry.key;
                        final cat = entry.value;
                        final porcentaje = (cat['porcentaje'] as num?)?.toDouble() ?? 0;
                        final color = colores[index % colores.length];
                        
                        return PieChartSectionData(
                          value: porcentaje,
                          title: '${porcentaje.toStringAsFixed(0)}%',
                          color: color,
                          radius: 38,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              else
                const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Sin categorías', style: TextStyle(fontSize: 11)),
                  ),
                ),
              
              const SizedBox(height: 10),
              
              // Leyenda con totales
              if (categorias.isNotEmpty)
                ...categorias.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  final nombreCat = cat['nombre'];
                  final totalCat = (cat['total'] as num).toDouble();
                  final color = colores[index % colores.length];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            nombreCat,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalCat),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesMes(Map<String, dynamic> mesData) {
    final String mesStr = mesData['mes'];
    final double totalMes = (mesData['total_mes'] as num).toDouble();
    final List<dynamic> categorias = mesData['categorias'];

    final parts = mesStr.split('-');
    final year = parts[0];
    final month = parts[1];
    
    final mesesNombres = {
      '01': 'Enero', '02': 'Febrero', '03': 'Marzo', '04': 'Abril',
      '05': 'Mayo', '06': 'Junio', '07': 'Julio', '08': 'Agosto',
      '09': 'Septiembre', '10': 'Octubre', '11': 'Noviembre', '12': 'Diciembre'
    };
    final mesNombre = mesesNombres[month] ?? month;
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$mesNombre $year'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${currencyFormat.format(totalMes)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Desglose por categoría:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (categorias.isEmpty)
                const Text('Sin categorías')
              else
                ...categorias.map((cat) {
                  final nombreCat = cat['nombre'];
                  final totalCat = (cat['total'] as num).toDouble();
                  final porcentaje = (cat['porcentaje'] as num?)?.toDouble() ?? 0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombreCat,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${porcentaje.toStringAsFixed(1)}% del total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(totalCat),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

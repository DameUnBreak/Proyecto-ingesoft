import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/api/health/');
    final response = await http.get(url);
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> registerUser(
    String nombre,
    String correo,
    String contrasena,
  ) async {
    final url = Uri.parse('$baseUrl/api/usuarios/crear/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  Future<Map<String, dynamic>> login(
    String correo,
    String contrasena,
  ) async {
    final url = Uri.parse('$baseUrl/api/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': correo,
        'contrasena': contrasena,
      }),
    );

    return {
      'status': response.statusCode,
      'body': jsonDecode(response.body),
    };
  }

  /// ✅ Obtener listas de un usuario (soporta lista directa o objeto con "results"/"listas")
  Future<List<dynamic>> getListas(int usuarioId) async {
    final url = Uri.parse('$baseUrl/api/listas/?usuario_id=$usuarioId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        // [ {...}, {...} ]
        return decoded;
      } else if (decoded is Map<String, dynamic>) {
        // { "results": [ ... ] } o { "listas": [ ... ] } o similar
        final inner =
            decoded['results'] ?? decoded['listas'] ?? decoded['data'];

        if (inner is List) {
          return inner;
        } else {
          throw Exception('Formato inesperado de listas en la respuesta');
        }
      } else {
        throw Exception('Respuesta inesperada del servidor al obtener listas');
      }
    } else {
      throw Exception('Error al obtener listas (${response.statusCode})');
    }
  }

  /// ✅ Crear lista (nombre + presupuesto opcional) para un usuario
  Future<bool> crearLista(String nombre, double? presupuesto, int usuarioId) async {
    final url = Uri.parse('$baseUrl/api/listas/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'presupuesto': presupuesto,
        'usuario_id': usuarioId,
      }),
    );

    return response.statusCode == 201;
  }

  /// ✅ Actualizar lista (editar nombre/presupuesto)
  Future<bool> actualizarLista(
    int id,
    String nombre,
    double? presupuesto,
  ) async {
    final url = Uri.parse('$baseUrl/api/listas/$id/');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'presupuesto': presupuesto,
      }),
    );

    // DRF suele devolver 200 o 202 al actualizar
    return response.statusCode == 200 || response.statusCode == 202;
  }

  /// ✅ Eliminar lista
  Future<bool> eliminarLista(int id) async {
    // Asumo endpoint REST estándar de DRF: /api/listas/<id>/
    final url = Uri.parse('$baseUrl/api/listas/$id/');
    final response = await http.delete(url);

    // DRF suele devolver 204, pero por si acaso aceptamos 200 también
    return response.statusCode == 204 || response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getResumenLista(int listaId) async {
    final url = Uri.parse('$baseUrl/api/resumen_lista/$listaId/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<String>> getRecomendaciones(int listaId) async {
    final url = Uri.parse('$baseUrl/api/recomendaciones/$listaId/');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data);
    }

    return [];
  }

  /// ITEMS

  Future<bool> crearItem(
    int listaId,
    String nombre,
    int cantidad,
    String categoria,
    double precioUnitario,
  ) async {
    final url = Uri.parse('$baseUrl/api/items/');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "lista_id": listaId,
        "nombre": nombre,
        "cantidad": cantidad,
        "categoria": categoria,
        "precio_unitario": precioUnitario,
      }),
    );

    return response.statusCode == 201;
  }

  Future<List<dynamic>> getItems(int listaId) async {
    final url = Uri.parse('$baseUrl/api/items/?lista_id=$listaId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('items')) {
        return data['items'];
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getItemDetalle(int id) async {
    final url = Uri.parse('$baseUrl/api/items/$id/');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  Future<bool> editarItem(
    int id,
    String nombre,
    String categoria,
    int cantidad,
    double precioUnitario,
  ) async {
    final url = Uri.parse('$baseUrl/api/items/$id/');

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": nombre,
        'cantidad': cantidad,
        'categoria': categoria,
        'precio_unitario': precioUnitario,
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> borrarItem(int id) async {
    final url = Uri.parse('$baseUrl/api/items/$id/');

    final response = await http.delete(url);

    return response.statusCode == 200;
  }
}

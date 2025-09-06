import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier.dart';
import '../config/environment.dart'; // Importa tu archivo de entorno
import 'package:shared_preferences/shared_preferences.dart';

class SupplierService {
  final String baseUrl = '${Environment.apiUrl}/suppliers';

  // Método para obtener el token del almacenamiento local
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // Obtener token de SharedPreferences
  }

  // Método para configurar los encabezados con el token de autorización
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getToken();
    if (token == null) {
      throw Exception('Token no encontrado');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Añadir el token al encabezado
    };
  }

  // Listar proveedores activos
  Future<List<Supplier>> listarActivos() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Supplier.fromJson(json)).toList();
    } else {
      throw Exception('Error al listar proveedores activos');
    }
  }

  // Listar proveedores inactivos
  Future<List<Supplier>> listarInactivos() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inactivos'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Supplier.fromJson(json)).toList();
    } else {
      throw Exception('Error al listar proveedores inactivos');
    }
  }

  // Buscar proveedor por ID
  Future<Supplier> buscarPorId(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Supplier.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Proveedor no encontrado');
    }
  }

  // Crear un nuevo proveedor
  Future<Supplier> crear(Supplier supplier) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(supplier.toJson()),
    );

    if (response.statusCode == 200) {
      return Supplier.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear proveedor');
    }
  }

  // Actualizar proveedor
  Future<Supplier> actualizar(int id, Supplier supplier) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(supplier.toJson()),
    );

    if (response.statusCode == 200) {
      return Supplier.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al actualizar proveedor');
    }
  }

  // Eliminación lógica de proveedor
  Future<void> eliminarLogico(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/eliminadologico/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar proveedor');
    }
  }

  // Reactivar proveedor
  Future<void> reactivar(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/reactivar/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al reactivar proveedor');
    }
  }
}

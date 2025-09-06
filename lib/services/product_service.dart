import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final String baseUrl = '${Environment.apiUrl}/products';

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

  // Listar productos activos ordenados de menor a mayor por ID
  Future<List<Product>> listarActivos() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      Iterable lista = json.decode(utf8.decode(response.bodyBytes));
      List<Product> products = List<Product>.from(
        lista.map((model) => Product.fromJson(model)),
      );

      // Ordenar de menor a mayor por productId
      products.sort((a, b) {
        // Manejar casos donde productId pueda ser null
        int idA = a.productId ?? 0;
        int idB = b.productId ?? 0;
        return idA.compareTo(idB);
      });

      return products;
    } else {
      throw Exception('Error al cargar productos activos');
    }
  }

  // Listar productos inactivos
  Future<List<Product>> listarInactivos() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inactivos'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      Iterable lista = json.decode(utf8.decode(response.bodyBytes));
      return List<Product>.from(lista.map((model) => Product.fromJson(model)));
    } else {
      throw Exception('Error al cargar productos inactivos');
    }
  }

  // Obtener producto por ID
  Future<Product> obtenerPorId(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Producto no encontrado');
    }
  }

  // Crear un nuevo producto
  Future<Product> crear(Product product) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear producto');
    }
  }

  // Actualizar producto
  Future<Product> actualizar(int id, Product product) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/actualizar/$id'),
      headers: headers,
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al actualizar producto');
    }
  }

  // Eliminar producto físicamente
  Future<void> eliminarFisico(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/eliminadofisico/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Error al eliminar producto físicamente');
    }
  }

  // Eliminar producto lógicamente
  Future<Product> eliminarLogico(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/eliminadologico/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al eliminar producto lógicamente');
    }
  }

  // Reactivar producto
  Future<Product> reactivar(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/reactivar/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al reactivar producto');
    }
  }
}

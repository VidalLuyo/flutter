import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../config/environment.dart'; // Importa tu archivo de entorno
import 'package:shared_preferences/shared_preferences.dart';

class ClientsService {
  final String baseUrl = '${Environment.apiUrl}/clients';

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

  // Obtener todos los clientes activos
  Future<List<Client>> getClients() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar clientes activos');
    }
  }

  // Obtener clientes inactivos
  Future<List<Client>> getInactiveClients() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/inactivos'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Client.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar clientes inactivos');
    }
  }

  // Obtener cliente por ID
  Future<Client> getClientById(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Client.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Cliente no encontrado');
    }
  }

  // Crear un nuevo cliente
  Future<Client> createClient(Client client) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(client.toJson()),
    );

    if (response.statusCode == 200) {
      return Client.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear cliente');
    }
  }

  // Actualizar cliente
  Future<Client> updateClient(int id, Client client) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode(client.toJson()),
    );

    if (response.statusCode == 200) {
      return Client.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al actualizar cliente');
    }
  }

  // Eliminación lógica de cliente
  Future<Client> deleteClient(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/eliminadologico/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Client.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al eliminar cliente lógicamente');
    }
  }

  // Restaurar cliente eliminado lógicamente
  Future<Client> restoreClient(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/reactivar/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Client.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al restaurar cliente');
    }
  }

  // Eliminación física de cliente
  Future<void> deleteClientPhysically(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/eliminadofisico/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar cliente físicamente');
    }
  }
}

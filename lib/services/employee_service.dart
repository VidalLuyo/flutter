import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../config/environment.dart'; // Importa tu archivo de entorno
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeService {
  final String baseUrl = '${Environment.apiUrl}/employees';

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

  // Obtener todos los empleados activos o inactivos
  Future<List<Employee>> getEmployees({bool active = true}) async {
    final url = active ? baseUrl : '$baseUrl/inactivos';
    final headers = await _getAuthHeaders();
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final List jsonData = json.decode(utf8.decode(response.bodyBytes));
      return jsonData.map((e) => Employee.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar empleados');
    }
  }

  // Obtener un empleado por su ID
  Future<Employee> getById(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Employee.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Empleado no encontrado');
    }
  }

  // Crear un nuevo empleado
  Future<void> create(Employee emp) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: json.encode(emp.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al registrar empleado');
    }
  }

  // Actualizar un empleado por su ID
  Future<void> update(int id, Employee emp) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: json.encode(emp.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar empleado');
    }
  }

  // Eliminación lógica
  Future<void> deleteLogical(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/eliminadologico/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar lógicamente');
    }
  }

  // Restaurar empleado eliminado lógicamente
  Future<void> restore(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/reactivar/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al restaurar empleado');
    }
  }

  // Eliminación física
  Future<void> deletePhysical(int id) async {
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/eliminadofisico/$id'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar permanentemente');
    }
  }
}

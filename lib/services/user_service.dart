import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart'; // Importa tu archivo de modelo User
import '../config/environment.dart'; // Asegúrate de que el archivo de entorno esté disponible

class UserService {
  final String baseUrl = '${Environment.apiUrl}/auth';

  // Login
  Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error en el login');
    }
  }

  // Obtener usuario por nombre de usuario
  Future<User> getUserByUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/me?username=$username'),
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Usuario no encontrado');
    }
  }

  // Actualizar rol de usuario
  Future<void> updateUserRole(int id, String newRole) async {
    final response = await http.put(
      Uri.parse('${Environment.apiUrl}/users/$id/role'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'role': newRole}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar rol');
    }
  }
}

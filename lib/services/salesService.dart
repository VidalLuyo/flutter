import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sale_saledetail.dart';
import '../config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesService {
  final String baseUrl = '${Environment.apiUrl}/sales';

  // Cache para nombres de productos
  static final Map<int, String> _productNameCache = {};

  // Método para obtener el token del almacenamiento local
  Future<String?> _getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  // Método para configurar los encabezados con el token de autorización
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no encontrado o inválido');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método helper para manejar respuestas HTTP
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } catch (e) {
        throw Exception('Error al decodificar respuesta JSON: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token expirado o inválido');
    } else if (response.statusCode == 403) {
      throw Exception('Sin permisos para realizar esta acción');
    } else if (response.statusCode == 404) {
      throw Exception('Recurso no encontrado');
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }

  // Método mejorado para obtener nombre de producto por ID con cache
  Future<String> getProductName(int productId) async {
    // Verificar cache primero
    if (_productNameCache.containsKey(productId)) {
      return _productNameCache[productId]!;
    }

    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(
            Uri.parse('${Environment.apiUrl}/products/$productId'),
            headers: headers,
          )
          .timeout(Duration(seconds: 10)); // Timeout de 10 segundos

      final data = _handleResponse(response);
      String productName = data['productName'] ?? 'Producto desconocido';

      // Guardar en cache
      _productNameCache[productId] = productName;
      return productName;
    } catch (e) {
      print('Error obteniendo nombre del producto $productId: $e');
      return 'Producto desconocido';
    }
  }

  // Limpiar cache de productos
  void clearProductNameCache() {
    _productNameCache.clear();
  }

  // Obtener todas las ventas ordenadas de menor a mayor por ID
  Future<List<Sale>> getAllSales() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse(baseUrl), headers: headers)
          .timeout(Duration(seconds: 15));

      final List<dynamic> data = _handleResponse(response);
      List<Sale> sales = data.map((json) => Sale.fromJson(json)).toList();

      // Ordenar de menor a mayor por saleId
      sales.sort((a, b) => (a.saleId ?? 0).compareTo(b.saleId ?? 0));

      return sales;
    } catch (e) {
      print('Error al cargar las ventas: $e');
      throw Exception('Error al cargar las ventas: $e');
    }
  }

  // Método mejorado para obtener detalles de venta con nombres de productos
  Future<List<SaleDetail>> getSaleDetailsWithProductNames(int saleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/$saleId'), headers: headers)
          .timeout(Duration(seconds: 15));

      final data = _handleResponse(response);

      // Verificar si la respuesta es una venta completa o solo detalles
      List<dynamic> detailsData;
      if (data is Map && data.containsKey('details')) {
        detailsData = data['details'] ?? [];
      } else if (data is List) {
        detailsData = data;
      } else {
        throw Exception('Formato de respuesta inesperado');
      }

      List<SaleDetail> details = [];

      for (var json in detailsData) {
        SaleDetail detail = SaleDetail.fromJson(json);
        // Obtener el nombre del producto si no viene en el JSON o es desconocido
        if (detail.productName == null ||
            detail.productName!.isEmpty ||
            detail.productName == 'Producto desconocido') {
          detail.productName = await getProductName(detail.idProduct);
        }
        details.add(detail);
      }

      return details;
    } catch (e) {
      print('Error al obtener detalles de la venta $saleId: $e');
      throw Exception('Error al obtener detalles de la venta: $e');
    }
  }

  // Obtener una venta por su ID
  Future<Sale> getSaleById(int saleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/$saleId'), headers: headers)
          .timeout(Duration(seconds: 15));

      final data = _handleResponse(response);
      return Sale.fromJson(data);
    } catch (e) {
      print('Error al obtener venta $saleId: $e');
      throw Exception('Error al obtener la venta: $e');
    }
  }

  // Crear una nueva venta con detalles
  Future<Sale> createSale(Sale sale) async {
    try {
      // Validaciones básicas
      if (sale.details == null || sale.details!.isEmpty) {
        throw Exception('La venta debe tener al menos un detalle');
      }

      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: headers,
            body: jsonEncode(sale.toJson()),
          )
          .timeout(Duration(seconds: 20));

      final data = _handleResponse(response);
      return Sale.fromJson(data);
    } catch (e) {
      print('Error al crear la venta: $e');
      throw Exception('Error al crear la venta: $e');
    }
  }

  // Actualizar una venta (cabeza + detalles)
  Future<Sale> updateSale(int saleId, Sale sale) async {
    try {
      // Validaciones básicas
      if (sale.details == null || sale.details!.isEmpty) {
        throw Exception('La venta debe tener al menos un detalle');
      }

      final headers = await _getAuthHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/$saleId'),
            headers: headers,
            body: jsonEncode(sale.toJson()),
          )
          .timeout(Duration(seconds: 20));

      final data = _handleResponse(response);
      return Sale.fromJson(data);
    } catch (e) {
      print('Error al actualizar la venta $saleId: $e');
      throw Exception('Error al actualizar la venta: $e');
    }
  }

  // Eliminar una venta lógicamente (marcar como inactiva)
  Future<void> deleteSale(int saleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(Uri.parse('$baseUrl/$saleId/delete'), headers: headers)
          .timeout(Duration(seconds: 15));

      // Verificar códigos de éxito
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al eliminar la venta $saleId: $e');
      throw Exception('Error al eliminar la venta: $e');
    }
  }

  // Reactivar una venta
  Future<void> reactivateSale(int saleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .put(Uri.parse('$baseUrl/$saleId/reactivate'), headers: headers)
          .timeout(Duration(seconds: 15));

      // Verificar códigos de éxito
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al reactivar la venta $saleId: $e');
      throw Exception('Error al reactivar la venta: $e');
    }
  }

  // Obtener todas las ventas inactivas
  Future<List<Sale>> getInactiveSales() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/inactive'), headers: headers)
          .timeout(Duration(seconds: 15));

      final List<dynamic> data = _handleResponse(response);
      List<Sale> sales = data.map((json) => Sale.fromJson(json)).toList();

      // Ordenar por fecha o ID
      sales.sort((a, b) => (a.saleId ?? 0).compareTo(b.saleId ?? 0));

      return sales;
    } catch (e) {
      print('Error al cargar ventas inactivas: $e');
      throw Exception('Error al cargar ventas inactivas: $e');
    }
  }

  // Método para generar reporte PDF de una venta específica
  Future<List<int>> getSaleReportPdf(int saleId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/pdf/$saleId'), headers: headers)
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al generar reporte PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al obtener reporte PDF de venta $saleId: $e');
      throw Exception('Error al obtener reporte PDF: $e');
    }
  }

  // Método para generar reporte general de ventas activas
  Future<List<int>> getGeneralSalesReportPdf() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/reporte-general'), headers: headers)
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'Error al generar reporte general: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error al obtener reporte general: $e');
      throw Exception('Error al obtener reporte general: $e');
    }
  }

  // Método para generar reporte por rango de fechas
  Future<List<int>> getSalesReportByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      String startDateStr = startDate.toIso8601String().split('T')[0];
      String endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/reporte-por-fecha?startDate=$startDateStr&endDate=$endDateStr',
            ),
            headers: headers,
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'Error al generar reporte por fechas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error al obtener reporte por fechas: $e');
      throw Exception('Error al obtener reporte por fechas: $e');
    }
  }

  // Método para verificar conectividad
  Future<bool> checkConnection() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .get(Uri.parse(baseUrl), headers: headers)
          .timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Error de conectividad: $e');
      return false;
    }
  }
}

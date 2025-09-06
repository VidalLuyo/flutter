import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/client.dart';
import 'package:myapp/models/employee.dart';
import 'package:myapp/models/product.dart';
import 'package:myapp/models/sale_saledetail.dart';
import 'package:myapp/services/ClientsService.dart';
import 'package:myapp/services/employee_service.dart';
import 'package:myapp/services/product_service.dart';
import 'package:myapp/services/salesService.dart';

class SaleFormScreen extends StatefulWidget {
  final Sale? sale;
  const SaleFormScreen({Key? key, this.sale}) : super(key: key);

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  // Services
  final _clientsService = ClientsService();
  final _productService = ProductService();
  final _employeeService = EmployeeService();
  final _salesService = SalesService();

  // Form variables
  Client? _selectedClient;
  Employee? _selectedEmployee;
  Product? _selectedProduct;
  String _selectedPaymentMethod = 'Efectivo';
  final _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Data lists
  List<Client> _clients = [];
  List<Employee> _employees = [];
  List<Product> _products = [];
  List<SaleDetail> _saleDetails = [];

  // Product names for existing sale details
  Map<int, String> _productNames = {};
  bool _isLoadingNames = false;

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  final _paymentMethods = ['Efectivo', 'Tarjeta', 'Yape/Plin'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _clientsService.getClients(),
        _employeeService.getEmployees(),
        _productService.listarActivos(),
      ]);

      setState(() {
        _clients = results[0] as List<Client>;
        _employees = results[1] as List<Employee>;
        _products =
            (results[2] as List<Product>).where((p) => p.stock > 0).toList();
        _isLoading = false;
      });

      if (widget.sale != null) {
        await _loadSaleData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al cargar datos: $e', Colors.red);
    }
  }

  Future<void> _loadSaleData() async {
    if (widget.sale == null) return;

    setState(() {
      _selectedClient = _clients.firstWhere(
        (c) => c.idClient == widget.sale!.idClient,
        orElse: () => _clients.first,
      );
      _selectedEmployee = _employees.firstWhere(
        (e) => e.employeeId == widget.sale!.employeeId,
        orElse: () => _employees.first,
      );
      _selectedPaymentMethod = widget.sale!.paymentMethod ?? 'Efectivo';
      _saleDetails = List.from(widget.sale!.details ?? []);
      _isLoadingNames = true;
    });

    // Cargar nombres de productos para los detalles existentes
    await _loadProductNames();
  }

  // Cargar nombres de productos igual que en SaleDetailScreen
  Future<void> _loadProductNames() async {
    try {
      for (SaleDetail detail in _saleDetails) {
        if (detail.productName == null ||
            detail.productName!.isEmpty ||
            detail.productName == 'Producto desconocido') {
          String productName = await _salesService.getProductName(
            detail.idProduct,
          );
          _productNames[detail.idProduct] = productName;
        } else {
          _productNames[detail.idProduct] = detail.productName!;
        }
      }
    } catch (e) {
      print('Error cargando nombres de productos: $e');
      // En caso de error, usar los nombres que ya están en el modelo
      for (SaleDetail detail in _saleDetails) {
        _productNames[detail.idProduct] =
            detail.productName ?? 'Producto desconocido';
      }
    } finally {
      setState(() {
        _isLoadingNames = false;
      });
    }
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Debe ser un número mayor que 0';
    return null;
  }

  void _addProduct() {
    if (_selectedProduct == null) {
      _showSnackBar('Selecciona un producto', Colors.red);
      return;
    }

    final validation = _validateQuantity(_quantityController.text);
    if (validation != null) {
      _showSnackBar(validation, Colors.red);
      return;
    }

    final quantity = int.parse(_quantityController.text);
    if (quantity > _selectedProduct!.stock) {
      _showSnackBar(
        'Stock insuficiente. Disponible: ${_selectedProduct!.stock}',
        Colors.red,
      );
      return;
    }

    final existingIndex = _saleDetails.indexWhere(
      (d) => d.idProduct == _selectedProduct!.productId,
    );

    if (existingIndex != -1) {
      final newQuantity = _saleDetails[existingIndex].quantity + quantity;
      if (newQuantity > _selectedProduct!.stock) {
        _showSnackBar('Stock insuficiente', Colors.red);
        return;
      }
      setState(() {
        _saleDetails[existingIndex].quantity = newQuantity;
        _saleDetails[existingIndex].total =
            newQuantity * _selectedProduct!.salePrice;
      });
    } else {
      setState(() {
        _saleDetails.add(
          SaleDetail(
            idProduct: _selectedProduct!.productId!,
            productName: _selectedProduct!.productName,
            quantity: quantity,
            price: _selectedProduct!.salePrice,
            total: quantity * _selectedProduct!.salePrice,
          ),
        );
        // Agregar el nombre al mapa
        _productNames[_selectedProduct!.productId!] =
            _selectedProduct!.productName;
      });
    }

    setState(() {
      _selectedProduct = null;
      _quantityController.clear();
    });
    _showSnackBar('Producto agregado', Colors.green);
  }

  void _removeProduct(int index) {
    final removedProduct = _saleDetails[index];
    setState(() {
      _saleDetails.removeAt(index);
      // Remover del mapa si no hay más productos con ese ID
      if (!_saleDetails.any((d) => d.idProduct == removedProduct.idProduct)) {
        _productNames.remove(removedProduct.idProduct);
      }
    });
    _showSnackBar('Producto eliminado', Colors.green);
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeProduct(index);
      return;
    }

    // Buscar el producto en la lista
    Product? product;
    try {
      product = _products.firstWhere(
        (p) => p.productId == _saleDetails[index].idProduct,
      );
    } catch (e) {
      // Si no está en productos activos, permitir la edición pero mostrar advertencia
      _showSnackBar(
        'Producto no encontrado en inventario activo',
        Colors.orange,
      );
    }

    // Si encontramos el producto, validar stock
    if (product != null && newQuantity > product.stock) {
      _showSnackBar(
        'Stock insuficiente. Disponible: ${product.stock}',
        Colors.red,
      );
      return;
    }

    setState(() {
      _saleDetails[index].quantity = newQuantity;
      _saleDetails[index].total = newQuantity * _saleDetails[index].price;
    });
  }

  double _calculateTotal() =>
      _saleDetails.fold(0.0, (sum, detail) => sum + (detail.total ?? 0.0));

  Future<void> _saveSale() async {
    // Validar solo los campos obligatorios del formulario principal
    if (_selectedClient == null || _selectedEmployee == null) {
      _showSnackBar('Selecciona cliente y empleado', Colors.red);
      return;
    }
    if (_saleDetails.isEmpty) {
      _showSnackBar('Agrega al menos un producto', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Actualizar nombres de productos en los detalles antes de guardar
      for (SaleDetail detail in _saleDetails) {
        if (_productNames.containsKey(detail.idProduct)) {
          detail.productName = _productNames[detail.idProduct]!;
        }
      }

      // Crear una nueva instancia de venta sin IDs de detalles para evitar conflictos
      final cleanedSaleDetails =
          _saleDetails.map((detail) {
            return SaleDetail(
              // NO incluir saleDetailId para evitar conflictos de versioning
              idProduct: detail.idProduct,
              productName: detail.productName,
              quantity: detail.quantity,
              price: detail.price,
              total: detail.total,
            );
          }).toList();

      final sale = Sale(
        saleId: widget.sale?.saleId,
        idClient: _selectedClient!.idClient!,
        employeeId: _selectedEmployee!.employeeId!,
        saleDate: _currentDate,
        total: _calculateTotal(),
        paymentMethod: _selectedPaymentMethod,
        details: cleanedSaleDetails,
      );

      Sale savedSale;
      if (widget.sale == null) {
        // Crear nueva venta
        savedSale = await _salesService.createSale(sale);
      } else {
        // Para edición, usar estrategia de retry con recarga
        savedSale = await _updateSaleWithRetry(sale);
      }

      _showSnackBar(
        widget.sale == null ? 'Venta creada' : 'Venta actualizada',
        Colors.green,
      );
      _showExportDialog(savedSale);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('ObjectOptimisticLockingFailureException') ||
          errorMessage.contains('Row was updated or deleted') ||
          errorMessage.contains('StaleObjectStateException') ||
          errorMessage.contains('another transaction')) {
        errorMessage =
            'Conflicto de concurrencia detectado. Usa "Recargar Venta" para obtener la versión más reciente.';
        _showAdvancedConflictDialog();
        return;
      } else if (errorMessage.contains('Sin permisos')) {
        errorMessage =
            'No tienes permisos para realizar esta acción. Contacta al administrador.';
      } else if (errorMessage.contains('Token expirado')) {
        errorMessage =
            'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
      } else if (errorMessage.contains('Error del servidor: 500')) {
        errorMessage = 'Error interno del servidor. Intenta más tarde.';
      }
      _showSnackBar('Error al guardar: $errorMessage', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // Estrategia de retry para actualizaciones con manejo de conflictos
  Future<Sale> _updateSaleWithRetry(Sale sale, {int maxRetries = 1}) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // En reintentos, obtener la venta más reciente primero
          await _reloadCurrentSale();
          // Recrear la venta con los datos actualizados
          final updatedSale = Sale(
            saleId: widget.sale?.saleId,
            idClient: _selectedClient!.idClient!,
            employeeId: _selectedEmployee!.employeeId!,
            saleDate: _currentDate,
            total: _calculateTotal(),
            paymentMethod: _selectedPaymentMethod,
            details:
                _saleDetails
                    .map(
                      (detail) => SaleDetail(
                        idProduct: detail.idProduct,
                        productName: detail.productName,
                        quantity: detail.quantity,
                        price: detail.price,
                        total: detail.total,
                      ),
                    )
                    .toList(),
          );
          return await _salesService.updateSale(
            widget.sale!.saleId!,
            updatedSale,
          );
        } else {
          return await _salesService.updateSale(widget.sale!.saleId!, sale);
        }
      } catch (e) {
        if (attempt == maxRetries ||
            (!e.toString().contains(
                  'ObjectOptimisticLockingFailureException',
                ) &&
                !e.toString().contains('StaleObjectStateException'))) {
          rethrow;
        }
        // Esperar un poco antes del siguiente intento
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    throw Exception('Falló después de $maxRetries reintentos');
  }

  void _showAdvancedConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('⚠️ Conflicto de Datos'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se detectó un conflicto de concurrencia:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Esta venta fue modificada por otro usuario'),
                Text('• Los datos actuales pueden estar desactualizados'),
                Text('• Se requiere recargar para continuar'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tus cambios no se han perdido. Después de recargar podrás aplicarlos nuevamente.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context, true); // Volver y recargar lista
                },
                child: Text('Cancelar y Volver'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context); // Cerrar diálogo
                  await _reloadCurrentSale();
                },
                child: Text('Recargar Venta'),
              ),
            ],
          ),
    );
  }

  Future<void> _reloadCurrentSale() async {
    if (widget.sale?.saleId == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedSale = await _salesService.getSaleById(widget.sale!.saleId!);

      // Actualizar los datos con la venta más reciente
      setState(() {
        _selectedClient = _clients.firstWhere(
          (c) => c.idClient == updatedSale.idClient,
          orElse: () => _clients.first,
        );
        _selectedEmployee = _employees.firstWhere(
          (e) => e.employeeId == updatedSale.employeeId,
          orElse: () => _employees.first,
        );
        _selectedPaymentMethod = updatedSale.paymentMethod ?? 'Efectivo';
        _saleDetails = List.from(updatedSale.details ?? []);
        _isLoading = false;
      });

      // Recargar nombres de productos
      await _loadProductNames();

      _showSnackBar(
        '✅ Venta recargada con los datos más recientes',
        Colors.green,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error al recargar la venta: $e', Colors.red);
    }
  }

  void _showExportDialog(Sale sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Venta ${widget.sale == null ? 'Creada' : 'Actualizada'}',
            ),
            content: const Text('¿Deseas exportar el reporte?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Más Tarde'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _exportReport(sale.saleId!);
                  Navigator.pop(context, true);
                },
                child: const Text('Exportar'),
              ),
            ],
          ),
    );
  }

  Future<void> _exportReport(int saleId) async {
    try {
      _showLoadingDialog();
      final pdfBytes = await _salesService.getSaleReportPdf(saleId);
      final fileName =
          'venta_${saleId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      Navigator.pop(context);
      await _shareReportAlternative(pdfBytes, fileName);
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Error al generar reporte: $e', Colors.red);
    }
  }

  // Método alternativo para compartir sin dependencias externas
  Future<void> _shareReportAlternative(
    List<int> pdfBytes,
    String fileName,
  ) async {
    try {
      // Convertir a base64 para evitar problemas de archivo
      final base64String = base64Encode(pdfBytes);

      // Mostrar diálogo con opciones
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.file_download, color: Colors.green[700]),
                  SizedBox(width: 8),
                  Text('Reporte Generado'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Reporte generado exitosamente'),
                  SizedBox(height: 8),
                  Text('📄 Archivo: $fileName'),
                  SizedBox(height: 8),
                  Text('📊 Tamaño: ${_formatBytes(pdfBytes.length)}'),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El reporte se ha generado correctamente. Puedes copiarlo al portapapeles.',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: base64String));
                    Navigator.of(context).pop();
                    _showSnackBar(
                      'Reporte copiado al portapapeles como Base64',
                      Colors.green,
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      _showSnackBar('Error al procesar reporte: $e', Colors.red);
    }
  }

  // Formatear bytes para mostrar tamaño del archivo
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Generando reporte...'),
              ],
            ),
          ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.sale == null ? 'Nueva Venta' : 'Editar Venta',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCard('Información General', Icons.info, [
                        _buildDateField(),
                        _buildDropdown(
                          'Cliente *',
                          _selectedClient,
                          _clients,
                          (client) => '${client.firstName} ${client.lastName}',
                          (value) => setState(() => _selectedClient = value),
                          'Selecciona un cliente',
                        ),
                        _buildDropdown(
                          'Empleado *',
                          _selectedEmployee,
                          _employees,
                          (employee) =>
                              '${employee.firstName} ${employee.lastName}',
                          (value) => setState(() => _selectedEmployee = value),
                          'Selecciona un empleado',
                        ),
                        _buildDropdown(
                          'Método de Pago',
                          _selectedPaymentMethod,
                          _paymentMethods,
                          (method) => method,
                          (value) =>
                              setState(() => _selectedPaymentMethod = value!),
                          null,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildCard('Agregar Productos', Icons.add_shopping_cart, [
                        _buildDropdown(
                          'Producto',
                          _selectedProduct,
                          _products,
                          (product) =>
                              '${product.productName} (Stock: ${product.stock})',
                          (value) => setState(() => _selectedProduct = value),
                          null,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Solo requerido para agregar producto',
                                ),
                                // NO validador aquí - solo para agregar productos
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Precio: S/. ${_selectedProduct?.salePrice.toStringAsFixed(2) ?? '0.00'}',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addProduct,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Producto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildCard('Productos Agregados', Icons.list, [
                        if (_saleDetails.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No hay productos agregados'),
                            ),
                          )
                        else if (_isLoadingNames)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text('Cargando nombres de productos...'),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_saleDetails.length, (index) {
                            final detail = _saleDetails[index];
                            // Usar el nombre del mapa si está disponible
                            final productName =
                                _productNames[detail.idProduct] ??
                                detail.productName ??
                                'Producto desconocido';

                            return Card(
                              child: ListTile(
                                title: Text(productName),
                                subtitle: Text(
                                  'Precio: S/. ${detail.price.toStringAsFixed(2)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        initialValue:
                                            detail.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (value) {
                                          final qty = int.tryParse(value);
                                          if (qty != null && qty > 0) {
                                            _updateQuantity(index, qty);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'S/. ${detail.total?.toStringAsFixed(2) ?? '0.00'}',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeProduct(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ]),
                      const SizedBox(height: 16),
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'S/. ${_calculateTotal().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSale,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                          ),
                          child:
                              _isSaving
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    widget.sale == null
                                        ? 'CREAR VENTA'
                                        : 'ACTUALIZAR VENTA',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: child,
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    String Function(T) itemBuilder,
    void Function(T?) onChanged,
    String? validator,
  ) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items:
          items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemBuilder(item)),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: validator != null ? (v) => v == null ? validator : null : null,
    );
  }
}

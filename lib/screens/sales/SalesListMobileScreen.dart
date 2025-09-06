import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/models/sale_saledetail.dart';
import 'package:myapp/models/client.dart';
import 'package:myapp/models/employee.dart';
import 'package:myapp/screens/sales/sale_detail_screen.dart';
import 'package:myapp/screens/sales/sale_form.dart';
import 'package:myapp/services/salesService.dart';
import 'package:myapp/services/ClientsService.dart';
import 'package:myapp/services/employee_service.dart';

class SalesListMobileScreen extends StatefulWidget {
  const SalesListMobileScreen({Key? key}) : super(key: key);

  @override
  State<SalesListMobileScreen> createState() => _SalesListMobileScreenState();
}

class _SalesListMobileScreenState extends State<SalesListMobileScreen> {
  final SalesService _salesService = SalesService();
  final ClientsService _clientsService = ClientsService();
  final EmployeeService _employeeService = EmployeeService();

  bool showInactives = false;
  bool _isLoading = false;

  // Filtros
  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];
  List<Client> _clients = [];
  List<Employee> _employees = [];

  // Controladores de filtros
  Client? _selectedClientFilter;
  Employee? _selectedEmployeeFilter;
  String? _selectedPaymentMethodFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;

  final List<String> _paymentMethods = ['Efectivo', 'Tarjeta', 'Yape/Plin'];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
    _refreshVentas();
  }

  Future<void> _loadFilterData() async {
    try {
      final clients = await _clientsService.getClients();
      final employees = await _employeeService.getEmployees();
      setState(() {
        _clients = clients;
        _employees = employees;
      });
    } catch (e) {
      print('Error cargando datos de filtros: $e');
    }
  }

  Future<void> _refreshVentas() async {
    setState(() => _isLoading = true);
    try {
      final sales =
          showInactives
              ? await _salesService.getInactiveSales()
              : await _salesService.getAllSales();
      setState(() {
        _allSales = sales;
        _filteredSales = sales;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar ventas: $e');
    }
  }

  void _applyFilters() {
    List<Sale> filtered = List.from(_allSales);

    if (_selectedClientFilter != null) {
      filtered =
          filtered
              .where((sale) => sale.idClient == _selectedClientFilter!.idClient)
              .toList();
    }

    if (_selectedEmployeeFilter != null) {
      filtered =
          filtered
              .where(
                (sale) =>
                    sale.employeeId == _selectedEmployeeFilter!.employeeId,
              )
              .toList();
    }

    if (_selectedPaymentMethodFilter != null) {
      filtered =
          filtered
              .where(
                (sale) => sale.paymentMethod == _selectedPaymentMethodFilter,
              )
              .toList();
    }

    if (_startDateFilter != null && _endDateFilter != null) {
      filtered =
          filtered.where((sale) {
            if (sale.saleDate == null) return false;
            try {
              DateTime saleDate = DateTime.parse(sale.saleDate!);
              return saleDate.isAfter(
                    _startDateFilter!.subtract(Duration(days: 1)),
                  ) &&
                  saleDate.isBefore(_endDateFilter!.add(Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();
    }

    setState(() {
      _filteredSales = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedClientFilter = null;
      _selectedEmployeeFilter = null;
      _selectedPaymentMethodFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
      _filteredSales = _allSales;
    });
  }

  void _toggleInactiveSales() {
    setState(() {
      showInactives = !showInactives;
    });
    _refreshVentas();
  }

  // Función principal para abrir PDF en el navegador
  Future<void> _openPdfInBrowser(List<int> pdfBytes, String fileName) async {
    try {
      // Convertir PDF a base64
      String base64Pdf = base64Encode(pdfBytes);

      // Crear data URL para el PDF
      String dataUrl = 'data:application/pdf;base64,$base64Pdf';

      // Intentar abrir en el navegador
      Uri pdfUri = Uri.parse(dataUrl);

      if (await canLaunchUrl(pdfUri)) {
        await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication, // Abre en una nueva pestaña
        );

        _showSuccessSnackBar('PDF abierto en el navegador');
      } else {
        // Fallback: mostrar opciones alternativas
        _showPdfOptionsDialog(base64Pdf, fileName, dataUrl);
      }
    } catch (e) {
      // Si falla la apertura automática, mostrar opciones
      String base64Pdf = base64Encode(pdfBytes);
      String dataUrl = 'data:application/pdf;base64,$base64Pdf';
      _showPdfOptionsDialog(base64Pdf, fileName, dataUrl);
    }
  }

  // Diálogo con opciones para el PDF
  void _showPdfOptionsDialog(
    String base64Pdf,
    String fileName,
    String dataUrl,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Text('Opciones de PDF'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selecciona cómo quieres acceder al PDF:'),
                  SizedBox(height: 16),

                  // Opción 1: Copiar enlace directo
                  ListTile(
                    leading: Icon(Icons.link, color: Colors.blue),
                    title: Text('Copiar enlace directo'),
                    subtitle: Text('Pega el enlace en tu navegador'),
                    onTap: () async {
                      await _copyToClipboard(dataUrl);
                      Navigator.of(context).pop();
                      _showSuccessSnackBar(
                        'Enlace copiado. Pégalo en tu navegador',
                      );
                    },
                  ),

                  Divider(),

                  // Opción 2: Copiar base64
                  ListTile(
                    leading: Icon(Icons.code, color: Colors.green),
                    title: Text('Copiar código Base64'),
                    subtitle: Text('Para usar con visor PDF online'),
                    onTap: () async {
                      await _copyToClipboard(base64Pdf);
                      Navigator.of(context).pop();
                      _showSuccessSnackBar('Base64 copiado al portapapeles');
                    },
                  ),

                  Divider(),

                  // Opción 3: Abrir con visor online
                  ListTile(
                    leading: Icon(Icons.open_in_browser, color: Colors.orange),
                    title: Text('Visor PDF Online'),
                    subtitle: Text('Abrir con herramienta externa'),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _openWithOnlineViewer(base64Pdf);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  // Copiar al portapapeles
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      _showErrorSnackBar('Error al copiar: $e');
    }
  }

  // Abrir con visor PDF online
  Future<void> _openWithOnlineViewer(String base64Pdf) async {
    try {
      // PDF24 (visor online gratuito)
      String pdf24Url = 'https://tools.pdf24.org/en/view-pdf';

      Uri viewerUri = Uri.parse(pdf24Url);

      if (await canLaunchUrl(viewerUri)) {
        await launchUrl(viewerUri, mode: LaunchMode.externalApplication);
        _showInfoDialog(
          'Visor PDF Abierto',
          'Se abrió el visor PDF online. Pega el código Base64 que se copió automáticamente.',
        );

        // Copiar automáticamente el base64
        await _copyToClipboard(base64Pdf);
      } else {
        _showErrorSnackBar('No se pudo abrir el visor online');
      }
    } catch (e) {
      _showErrorSnackBar('Error al abrir visor: $e');
    }
  }

  // Exportar reportes con nueva funcionalidad
  Future<void> _exportReport(String type, {int? saleId}) async {
    try {
      _showLoadingDialog('Generando PDF...');

      List<int> pdfBytes;
      String fileName;

      switch (type) {
        case 'sale':
          if (saleId == null) {
            Navigator.of(context).pop();
            _showErrorSnackBar('ID de venta no válido');
            return;
          }
          pdfBytes = await _salesService.getSaleReportPdf(saleId);
          fileName =
              'venta_${saleId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          break;

        case 'general':
          pdfBytes = await _salesService.getGeneralSalesReportPdf();
          fileName =
              'reporte_ventas_general_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
          break;

        case 'range':
          if (_startDateFilter == null || _endDateFilter == null) {
            Navigator.of(context).pop();
            _showErrorSnackBar('Selecciona un rango de fechas para exportar');
            return;
          }
          pdfBytes = await _salesService.getSalesReportByDateRange(
            _startDateFilter!,
            _endDateFilter!,
          );
          fileName =
              'reporte_ventas_${DateFormat('yyyyMMdd').format(_startDateFilter!)}_${DateFormat('yyyyMMdd').format(_endDateFilter!)}.pdf';
          break;

        default:
          Navigator.of(context).pop();
          return;
      }

      Navigator.of(context).pop();

      // Abrir PDF en el navegador
      await _openPdfInBrowser(pdfBytes, fileName);
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error al generar reporte: $e');
    }
  }

  Future<void> _deleteSale(int saleId) async {
    final confirmed = await _showConfirmationDialog(
      title: '¿Eliminar venta?',
      content:
          'Esta acción marcará la venta como inactiva. Podrás restaurarla más tarde.',
      accentColor: Colors.red.shade600,
      icon: Icons.delete_outline,
    );

    if (!confirmed) return;

    try {
      await _salesService.deleteSale(saleId);
      _refreshVentas();
      _showSuccessSnackBar('Venta eliminada correctamente');
    } catch (error) {
      _showErrorSnackBar('Error al eliminar la venta: $error');
    }
  }

  Future<void> _reactivateSale(int saleId) async {
    try {
      await _salesService.reactivateSale(saleId);
      _refreshVentas();
      _showSuccessSnackBar('Venta reactivada correctamente');
    } catch (error) {
      _showErrorSnackBar('Error al reactivar la venta: $error');
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required Color accentColor,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(icon, color: accentColor),
                  SizedBox(width: 8),
                  Expanded(child: Text(title)),
                ],
              ),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Expanded(child: Text(message)),
              ],
            ),
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Entendido'),
              ),
            ],
          ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            clients: _clients,
            employees: _employees,
            paymentMethods: _paymentMethods,
            selectedClient: _selectedClientFilter,
            selectedEmployee: _selectedEmployeeFilter,
            selectedPaymentMethod: _selectedPaymentMethodFilter,
            startDate: _startDateFilter,
            endDate: _endDateFilter,
            onApplyFilters: (
              client,
              employee,
              paymentMethod,
              startDate,
              endDate,
            ) {
              setState(() {
                _selectedClientFilter = client;
                _selectedEmployeeFilter = employee;
                _selectedPaymentMethodFilter = paymentMethod;
                _startDateFilter = startDate;
                _endDateFilter = endDate;
              });
              _applyFilters();
            },
          ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Text('Generar Reportes PDF'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ExportOption(
                  icon: Icons.description,
                  title: 'Reporte General',
                  subtitle: 'Todas las ventas del sistema',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportReport('general');
                  },
                ),
                Divider(),
                _ExportOption(
                  icon: Icons.date_range,
                  title: 'Reporte por Rango',
                  subtitle: 'Ventas entre fechas seleccionadas',
                  color: Colors.green,
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportReport('range');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        centerTitle: true,
        elevation: 6,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          showInactives ? 'Ventas Inactivas' : 'Registro de Ventas',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFiltersDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshVentas,
          ),
          IconButton(
            icon: Icon(
              showInactives ? Icons.visibility : Icons.visibility_off_outlined,
              color: Colors.white,
            ),
            onPressed: _toggleInactiveSales,
          ),
        ],
      ),
      body: Column(
        children: [
          // Botones de acción superiores
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SaleFormScreen(),
                        ),
                      );
                      if (result == true) _refreshVentas();
                    },
                    icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                    label: Text(
                      'Nueva Venta',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showExportDialog,
                    icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: Text(
                      'Ver PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mostrar filtros activos
          if (_selectedClientFilter != null ||
              _selectedEmployeeFilter != null ||
              _selectedPaymentMethodFilter != null ||
              _startDateFilter != null ||
              _endDateFilter != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtros aplicados',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Lista de ventas
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.indigo),
                    )
                    : _filteredSales.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            showInactives
                                ? Icons.visibility_off
                                : Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16),
                          Text(
                            showInactives
                                ? 'No hay ventas inactivas'
                                : 'No hay ventas registradas',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _refreshVentas,
                            icon: Icon(Icons.refresh),
                            label: Text('Recargar'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      color: Colors.indigo,
                      onRefresh: _refreshVentas,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final sale = _filteredSales[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            SaleDetailScreen(sale: sale),
                                  ),
                                );
                                if (resultado == true) _refreshVentas();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              Colors.indigo.shade100,
                                          child: Icon(
                                            Icons.receipt_long_outlined,
                                            size: 24,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Venta #${sale.saleId?.toString().padLeft(4, '0') ?? "0000"}',
                                                style: theme
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          Colors
                                                              .indigo
                                                              .shade900,
                                                    ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                sale.total != null
                                                    ? 'S/. ${sale.total!.toStringAsFixed(2)}'
                                                    : 'S/. 0.00',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Botones de acción
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.red.shade600,
                                                size: 22,
                                              ),
                                              tooltip: 'Ver PDF',
                                              onPressed:
                                                  () => _exportReport(
                                                    'sale',
                                                    saleId: sale.saleId,
                                                  ),
                                            ),
                                            if (!showInactives)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.blue.shade600,
                                                  size: 22,
                                                ),
                                                tooltip: 'Editar venta',
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  SaleFormScreen(
                                                                    sale: sale,
                                                                  ),
                                                        ),
                                                      );
                                                  if (result == true)
                                                    _refreshVentas();
                                                },
                                              ),
                                            IconButton(
                                              icon: Icon(
                                                showInactives
                                                    ? Icons.restore
                                                    : Icons.delete_outline,
                                                color:
                                                    showInactives
                                                        ? Colors.green.shade600
                                                        : Colors.red.shade600,
                                                size: 22,
                                              ),
                                              tooltip:
                                                  showInactives
                                                      ? 'Reactivar venta'
                                                      : 'Eliminar venta',
                                              onPressed: () {
                                                if (showInactives) {
                                                  _reactivateSale(
                                                    sale.saleId ?? 0,
                                                  );
                                                } else {
                                                  _deleteSale(sale.saleId ?? 0);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _InfoChip(
                                          icon: Icons.calendar_today,
                                          label: sale.saleDate ?? '-',
                                        ),
                                        SizedBox(width: 8),
                                        _InfoChip(
                                          icon: Icons.payment,
                                          label: sale.paymentMethod ?? '-',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// Widget para opciones de exportación
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

// Widget para chips de información
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({Key? key, required this.icon, required this.label})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Diálogo de filtros
class FilterDialog extends StatefulWidget {
  final List<Client> clients;
  final List<Employee> employees;
  final List<String> paymentMethods;
  final Client? selectedClient;
  final Employee? selectedEmployee;
  final String? selectedPaymentMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(Client?, Employee?, String?, DateTime?, DateTime?)
  onApplyFilters;

  const FilterDialog({
    Key? key,
    required this.clients,
    required this.employees,
    required this.paymentMethods,
    this.selectedClient,
    this.selectedEmployee,
    this.selectedPaymentMethod,
    this.startDate,
    this.endDate,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  Client? _tempSelectedClient;
  Employee? _tempSelectedEmployee;
  String? _tempSelectedPaymentMethod;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _tempSelectedClient = widget.selectedClient;
    _tempSelectedEmployee = widget.selectedEmployee;
    _tempSelectedPaymentMethod = widget.selectedPaymentMethod;
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filtros de Búsqueda'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtro por cliente
            DropdownButtonFormField<Client>(
              value: _tempSelectedClient,
              decoration: InputDecoration(
                labelText: 'Cliente',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                DropdownMenuItem<Client>(
                  value: null,
                  child: Text('Todos los clientes'),
                ),
                ...widget.clients.map(
                  (client) => DropdownMenuItem<Client>(
                    value: client,
                    child: Text('${client.firstName} ${client.lastName}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _tempSelectedClient = value),
            ),
            SizedBox(height: 16),

            // Filtro por empleado
            DropdownButtonFormField<Employee>(
              value: _tempSelectedEmployee,
              decoration: InputDecoration(
                labelText: 'Empleado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              items: [
                DropdownMenuItem<Employee>(
                  value: null,
                  child: Text('Todos los empleados'),
                ),
                ...widget.employees.map(
                  (employee) => DropdownMenuItem<Employee>(
                    value: employee,
                    child: Text('${employee.firstName} ${employee.lastName}'),
                  ),
                ),
              ],
              onChanged:
                  (value) => setState(() => _tempSelectedEmployee = value),
            ),
            SizedBox(height: 16),

            // Filtro por método de pago
            DropdownButtonFormField<String>(
              value: _tempSelectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los métodos'),
                ),
                ...widget.paymentMethods.map(
                  (method) => DropdownMenuItem<String>(
                    value: method,
                    child: Text(method),
                  ),
                ),
              ],
              onChanged:
                  (value) => setState(() => _tempSelectedPaymentMethod = value),
            ),
            SizedBox(height: 16),

            // Filtro por fecha de inicio
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Fecha de inicio'),
              subtitle: Text(
                _tempStartDate != null
                    ? DateFormat('dd/MM/yyyy').format(_tempStartDate!)
                    : 'No seleccionada',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _tempStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _tempStartDate = date);
                }
              },
            ),

            // Filtro por fecha de fin
            ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Fecha de fin'),
              subtitle: Text(
                _tempEndDate != null
                    ? DateFormat('dd/MM/yyyy').format(_tempEndDate!)
                    : 'No seleccionada',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _tempEndDate ?? DateTime.now(),
                  firstDate: _tempStartDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _tempEndDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _tempSelectedClient = null;
              _tempSelectedEmployee = null;
              _tempSelectedPaymentMethod = null;
              _tempStartDate = null;
              _tempEndDate = null;
            });
          },
          child: Text('Limpiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyFilters(
              _tempSelectedClient,
              _tempSelectedEmployee,
              _tempSelectedPaymentMethod,
              _tempStartDate,
              _tempEndDate,
            );
            Navigator.of(context).pop();
          },
          child: Text('Aplicar'),
        ),
      ],
    );
  }
}

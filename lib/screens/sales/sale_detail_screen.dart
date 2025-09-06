import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/sale_saledetail.dart';
import 'package:myapp/screens/sales/sale_form.dart';
import 'package:myapp/services/salesService.dart';

class SaleDetailScreen extends StatefulWidget {
  final Sale sale;

  const SaleDetailScreen({Key? key, required this.sale}) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  final SalesService _salesService = SalesService();
  Map<int, String> _productNames = {};
  bool _isLoadingNames = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProductNames();
  }

  // Cargar nombres de productos
  Future<void> _loadProductNames() async {
    try {
      for (SaleDetail detail in widget.sale.details ?? []) {
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
      for (SaleDetail detail in widget.sale.details ?? []) {
        _productNames[detail.idProduct] =
            detail.productName ?? 'Producto desconocido';
      }
    } finally {
      setState(() {
        _isLoadingNames = false;
      });
    }
  }

  String formatDate(dynamic rawDate) {
    if (rawDate == null) return 'Fecha no disponible';

    if (rawDate is DateTime) {
      return DateFormat("dd 'de' MMMM 'del' yyyy", "es").format(rawDate);
    }

    try {
      final cleanDate = rawDate.toString().split(' ').first.split('T').first;
      final parsedDate = DateTime.parse(cleanDate).toLocal();
      return DateFormat("dd 'de' MMMM 'del' yyyy", "es").format(parsedDate);
    } catch (e) {
      print('Error parsing date: $e');
      return rawDate.toString();
    }
  }

  // Función para exportar reporte de esta venta (sin dependencias externas)
  Future<void> _exportSaleReport() async {
    setState(() => _isExporting = true);

    try {
      _showLoadingDialog('Generando reporte...');

      final pdfBytes = await _salesService.getSaleReportPdf(
        widget.sale.saleId!,
      );
      final fileName =
          'venta_${widget.sale.saleId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      Navigator.of(context).pop(); // Cerrar loading

      await _shareReportAlternative(pdfBytes, fileName);
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading
      _showErrorSnackBar('Error al generar reporte: $e');
    } finally {
      setState(() => _isExporting = false);
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
                  Text('Reporte de Venta'),
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
                  Text('🧾 Venta: #${widget.sale.saleId}'),
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
                            'El reporte PDF se ha generado correctamente. Puedes copiarlo al portapapeles.',
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
                    _showSuccessSnackBar(
                      'Reporte copiado al portapapeles como Base64',
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copiar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
      );
    } catch (e) {
      _showErrorSnackBar('Error al procesar reporte: $e');
    }
  }

  // Formatear bytes para mostrar tamaño del archivo
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editSale() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleFormScreen(sale: widget.sale),
      ),
    );

    if (result == true) {
      // Actualizar la pantalla padre
      Navigator.of(context).pop(true);
    }
  }

  Widget _sectionCard(BuildContext context, String title, Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.indigo.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.indigo.shade700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.indigo.shade500),
          const SizedBox(width: 16),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: valueColor ?? Colors.indigo.shade900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productDetailCard(
    BuildContext context,
    SaleDetail detail,
    int index,
  ) {
    // Obtener el nombre del producto del mapa cargado
    String productName = _productNames[detail.idProduct] ?? 'Cargando...';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.indigo.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Producto: $productName',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _productInfoRow(
                    Icons.inventory_2,
                    'Cantidad',
                    '${detail.quantity}',
                  ),
                ),
                Expanded(
                  child: _productInfoRow(
                    Icons.attach_money,
                    'Precio',
                    'S/. ${detail.price.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'S/. ${detail.total?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo.shade900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.indigo.shade400),
        const SizedBox(width: 6),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.indigo.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.indigo.shade800,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.indigo.shade900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 6,
        shadowColor: Colors.indigoAccent.withOpacity(0.6),
        centerTitle: true,
        title: const Text(
          'Detalles de la Venta',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.6,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Atrás',
          color: Colors.white,
          splashRadius: 24,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            tooltip: 'Editar venta',
            onPressed: _editSale,
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            tooltip: 'Exportar reporte',
            onPressed: _isExporting ? null : _exportSaleReport,
          ),
        ],
      ),
      body:
          _isLoadingNames
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'Venta #${widget.sale.saleId?.toString().padLeft(4, '0') ?? "0000"}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionCard(
                      context,
                      'Información General',
                      Column(
                        children: [
                          _infoRow(
                            Icons.calendar_today,
                            'Fecha de Venta',
                            formatDate(widget.sale.saleDate),
                          ),
                          _infoRow(
                            Icons.payment,
                            'Método de Pago',
                            widget.sale.paymentMethod ?? 'No especificado',
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      context,
                      'Resumen Financiero',
                      Column(
                        children: [
                          _infoRow(
                            Icons.receipt_long,
                            'Cantidad de Productos',
                            '${widget.sale.details?.length ?? 0} ${(widget.sale.details?.length ?? 0) == 1 ? 'producto' : 'productos'}',
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigo.shade100,
                                  Colors.indigo.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigo.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL GENERAL:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.indigo.shade700,
                                    fontSize: 18,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'S/. ${widget.sale.total?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.indigo.shade900,
                                    fontSize: 20,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _sectionCard(
                      context,
                      'Productos Vendidos',
                      Column(
                        children:
                            (widget.sale.details?.isNotEmpty ?? false)
                                ? widget.sale.details!.asMap().entries.map((
                                  entry,
                                ) {
                                  return _productDetailCard(
                                    context,
                                    entry.value,
                                    entry.key,
                                  );
                                }).toList()
                                : [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        'No hay productos en esta venta',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botones de acción mejorados
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Editar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _editSale,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isExporting
                                      ? Colors.grey
                                      : Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            icon:
                                _isExporting
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.file_download,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                            label: Text(
                              _isExporting ? 'Exportando...' : 'Exportar PDF',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _isExporting ? null : _exportSaleReport,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Botón adicional para compartir información básica
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.indigo.shade700,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          Icons.share,
                          size: 20,
                          color: Colors.indigo.shade700,
                        ),
                        label: Text(
                          'Compartir Información',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                        onPressed: () => _shareBasicInfo(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // Función para compartir información básica como texto (usando Clipboard)
  void _shareBasicInfo() {
    final saleInfo = '''
🧾 VENTA #${widget.sale.saleId?.toString().padLeft(4, '0') ?? "0000"}

📅 Fecha: ${formatDate(widget.sale.saleDate)}
💳 Método de pago: ${widget.sale.paymentMethod ?? 'No especificado'}

📦 PRODUCTOS:
${(widget.sale.details ?? []).asMap().entries.map((entry) {
      final detail = entry.value;
      final productName = _productNames[detail.idProduct] ?? 'Producto desconocido';
      return '${entry.key + 1}. $productName\n   Cantidad: ${detail.quantity} x S/. ${detail.price.toStringAsFixed(2)} = S/. ${detail.total?.toStringAsFixed(2) ?? '0.00'}';
    }).join('\n\n')}

💰 TOTAL: S/. ${widget.sale.total?.toStringAsFixed(2) ?? '0.00'}
    ''';

    // Usar Clipboard en lugar de Share
    Clipboard.setData(ClipboardData(text: saleInfo));
    _showSuccessSnackBar('Información de la venta copiada al portapapeles');
  }
}

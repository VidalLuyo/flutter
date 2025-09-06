import 'package:flutter/material.dart';
 // Import necesario para localizaciones
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';
import 'product_form_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  // ignore: use_super_parameters
  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  String get fullSupplierName {
    final n = product.supplier.names ?? '';
    final s = product.supplier.surnames ?? '';
    // ignore: prefer_interpolation_to_compose_strings
    return (n + ' ' + s).trim().isEmpty ? 'Proveedor no disponible' : '$n $s';
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
      // ignore: avoid_print
      print('Error parsing date: $e');
      return rawDate.toString();
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.indigo.shade900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 6,
        // ignore: deprecated_member_use
        shadowColor: Colors.indigoAccent.withOpacity(0.6),
        centerTitle: true,
        title: const Text(
          'Detalles del Producto',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                product.productName,
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
              'Descripción',
              Text(
                product.descripcion.isNotEmpty
                    ? product.descripcion
                    : 'No disponible',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            _sectionCard(
              context,
              'Información General',
              Column(
                children: [
                  _infoRow(Icons.storage, 'Stock', '${product.stock} unidades'),
                  _infoRow(Icons.local_shipping, 'Proveedor', fullSupplierName),
                ],
              ),
            ),
            _sectionCard(
              context,
              'Precios',
              Column(
                children: [
                  _infoRow(
                    Icons.attach_money,
                    'Precio de Compra',
                    'S/. ${product.purchasePrice.toStringAsFixed(2)}',
                  ),
                  _infoRow(
                    Icons.price_change,
                    'Precio de Venta',
                    'S/. ${product.salePrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            _sectionCard(
              context,
              'Otros Datos',
              Column(
                children: [
                  _infoRow(
                    Icons.date_range,
                    'Fecha de Registro',
                    formatDate(product.productDate),
                  ),
                  _infoRow(
                    product.status == 'A' ? Icons.check_circle : Icons.cancel,
                    'Estado',
                    product.status == 'A' ? 'Activo' : 'Inactivo',
                    valueColor:
                        product.status == 'A' ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (product.status == 'A')
              // ignore: deprecated_member_use
              ButtonBar(
                alignment: MainAxisAlignment.center,
                buttonPadding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 26,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 12,
                      // ignore: deprecated_member_use
                      shadowColor: Colors.blue.shade400.withOpacity(0.7),
                    ),
                    icon: const Icon(Icons.edit, size: 24, color: Colors.white),
                    label: const Text(
                      'Editar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: product),
                        ),
                      );
                      // ignore: use_build_context_synchronously
                      if (resultado == true) Navigator.pop(context, true);
                    },
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 26,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 12,
                      // ignore: deprecated_member_use
                      shadowColor: Colors.red.shade400.withOpacity(0.7),
                    ),
                    icon: const Icon(
                      Icons.delete,
                      size: 24,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.8,
                        fontFamily: 'Poppins',
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              // ignore: prefer_const_constructors
                              title: Row(
                                children: const [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Confirmar eliminación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                '¿Está seguro que desea eliminar este producto? Esta acción es reversible desde el módulo de productos inactivos.',
                                style: TextStyle(fontSize: 16, height: 1.4),
                              ),
                              actionsPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 10,
                                    shadowColor: Colors.red.shade400
                                        // ignore: deprecated_member_use
                                        .withOpacity(0.8),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                      );

                      if (confirm == true) {
                        await ProductService().eliminarLogico(
                          product.productId!,
                        );

                        // Mostrar SnackBar notificando la eliminación
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Producto eliminado correctamente'),
                            duration: Duration(seconds: 3),
                            backgroundColor: Colors.redAccent,
                          ),
                        );

                        // Cerrar la pantalla después de mostrar el SnackBar
                        // ignore: use_build_context_synchronously
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:myapp/screens/products/product_detail_screen.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductInactiveListScreen extends StatefulWidget {
  const ProductInactiveListScreen({Key? key}) : super(key: key);

  @override
  State<ProductInactiveListScreen> createState() =>
      _ProductInactiveListScreenState();
}

class _ProductInactiveListScreenState extends State<ProductInactiveListScreen> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productos;

  @override
  void initState() {
    super.initState();
    _productos = _productService.listarInactivos();
  }

  Future<void> _refreshProductos() async {
    setState(() {
      _productos = _productService.listarInactivos();
    });
  }

  void _showRestoreConfirmation(Product product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.restore_outlined,
                color: Colors.green.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmar reactivación',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Está seguro que desea reactivar este producto?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'El producto volverá a estar disponible en el inventario activo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restoreProduct(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reactivar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _restoreProduct(Product product) async {
    if (product.productId == null) {
      _showErrorSnackBar('Error: ID del producto no válido');
      return;
    }

    try {
      _showLoadingDialog('Reactivando producto...');

      await _productService.reactivar(product.productId!);

      if (mounted) Navigator.of(context).pop();

      _showSuccessSnackBar(
        'Producto "${product.productName}" reactivado correctamente',
      );

      await _refreshProductos();
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar(
        'Error al reactivar el producto: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
        elevation: 6,
        shadowColor: Colors.redAccent.withOpacity(0.7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Atrás',
          color: Colors.white,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/productos');
          },
        ),
        title: const Text(
          'Productos Inactivos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: 1.0,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<Product>>(
        future: _productos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.redAccent,
                    strokeWidth: 3.5,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando productos inactivos...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), theme);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyWidget(theme);
          }

          final productos = snapshot.data!;

          return RefreshIndicator(
            color: Colors.redAccent,
            onRefresh: _refreshProductos,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final product = productos[index];
                return _ProductInactiveCard(
                  product: product,
                  onTap: () => _navigateToProductDetail(product),
                  onRestore: () => _showRestoreConfirmation(product),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar productos inactivos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.replaceAll('Exception: ', ''),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshProductos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos inactivos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos los productos están activos',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToProductDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
    if (result == true) {
      _refreshProductos();
    }
  }
}

class _ProductInactiveCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onRestore;

  const _ProductInactiveCard({
    required this.product,
    required this.onTap,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.red.shade300.withOpacity(0.5),
      color: Colors.red[50],
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildLeadingIcon(),
              const SizedBox(width: 16),
              Expanded(child: _buildProductInfo(theme)),
              _buildTrailingActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade300, width: 1),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.red.shade600,
        size: 32,
      ),
    );
  }

  Widget _buildProductInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.productName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.red.shade900,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black12,
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.storage,
          label: 'Stock',
          value: '${product.stock} unidades',
        ),
        _InfoRow(
          icon: Icons.price_check,
          label: 'Precio venta',
          value: 'S/. ${product.salePrice.toStringAsFixed(2)}',
        ),
        _InfoRow(
          icon: Icons.local_shipping_outlined,
          label: 'Proveedor',
          value: _getSupplierName(product.supplier),
        ),
      ],
    );
  }

  String _getSupplierName(dynamic supplier) {
    if (supplier == null) return 'N/A';

    String nombres = supplier.names?.toString() ?? '';
    String apellidos = supplier.surnames?.toString() ?? '';

    String fullName = '$nombres $apellidos'.trim();
    return fullName.isEmpty ? 'N/A' : fullName;
  }

  Widget _buildTrailingActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onRestore,
          tooltip: 'Reactivar producto',
          icon: Icon(Icons.restore, color: Colors.green.shade700, size: 24),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

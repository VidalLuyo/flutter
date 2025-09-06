// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: library_prefixes
import '../../models/product.dart' as modeloProducto;
import '../../models/supplier.dart';
import '../../services/product_service.dart';
import '../../services/supplier_service.dart';

class ProductFormScreen extends StatefulWidget {
  final modeloProducto.Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  // Form and validation
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Services
  final ProductService _productService = ProductService();
  final SupplierService _supplierService = SupplierService();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _stockController;

  // State variables
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  List<String> _existingProductNames = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  int _currentStep = 0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _disposeControllers();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.product?.productName ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.descripcion ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice.toString() ?? '',
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
  }

  void _disposeControllers() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _supplierService.listarActivos(),
        _productService.listarActivos(),
      ]);

      final suppliers = results[0] as List<Supplier>;
      final products = results[1] as List<modeloProducto.Product>;

      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _existingProductNames =
              products
                  .where(
                    (p) =>
                        widget.product == null ||
                        p.productName.toLowerCase() !=
                            widget.product!.productName.toLowerCase(),
                  )
                  .map((p) => p.productName.toLowerCase())
                  .toList();

          _selectedSupplier = _getInitialSupplier(suppliers);
          _isInitialized = true;
        });

        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al cargar los datos: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Supplier? _getInitialSupplier(List<Supplier> suppliers) {
    if (widget.product != null && suppliers.isNotEmpty) {
      try {
        return suppliers.firstWhere(
          (s) => s.idSuppliers == widget.product!.supplier.idSuppliers,
        );
      } catch (e) {
        return suppliers.isNotEmpty ? suppliers.first : null;
      }
    }
    return suppliers.isNotEmpty ? suppliers.first : null;
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _purchasePriceController.clear();
      _salePriceController.clear();
      _stockController.clear();
      _selectedSupplier = _suppliers.isNotEmpty ? _suppliers.first : null;
      _currentStep = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _saveProduct() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    try {
      final product = _createProductFromForm();

      if (widget.product == null) {
        await _productService.crear(product);
        _showSuccessSnackBar('Producto creado exitosamente');
      } else {
        await _productService.actualizar(widget.product!.productId!, product);
        _showSuccessSnackBar('Producto actualizado exitosamente');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showErrorSnackBar('Error al guardar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  modeloProducto.Product _createProductFromForm() {
    return modeloProducto.Product(
      productId: widget.product?.productId,
      productName: _nameController.text.trim(),
      descripcion: _descriptionController.text.trim(),
      supplier: _selectedSupplier!,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      stock: int.parse(_stockController.text),
      status: 'A',
      productDate: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateBasicInfo();
      case 1:
        return _validatePricing();
      case 2:
        return _validateFinalDetails();
      default:
        return false;
    }
  }

  bool _validateBasicInfo() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final nameUnique =
        !_existingProductNames.contains(_nameController.text.toLowerCase());

    if (!nameValid) {
      _showErrorSnackBar('El nombre del producto es requerido');
      return false;
    }

    if (!nameUnique) {
      _showErrorSnackBar('El nombre del producto ya existe');
      return false;
    }

    return true;
  }

  bool _validatePricing() {
    final purchasePrice = double.tryParse(_purchasePriceController.text);
    final salePrice = double.tryParse(_salePriceController.text);

    if (purchasePrice == null || purchasePrice <= 0) {
      _showErrorSnackBar('Ingrese un precio de compra válido');
      return false;
    }

    if (salePrice == null || salePrice <= 0) {
      _showErrorSnackBar('Ingrese un precio de venta válido');
      return false;
    }

    if (salePrice <= purchasePrice) {
      _showErrorSnackBar(
        'El precio de venta debe ser mayor al precio de compra',
      );
      return false;
    }

    return true;
  }

  bool _validateFinalDetails() {
    final stock = int.tryParse(_stockController.text);

    if (stock == null || stock <= 0) {
      _showErrorSnackBar('Ingrese un stock válido');
      return false;
    }

    if (_selectedSupplier == null) {
      _showErrorSnackBar('Seleccione un proveedor');
      return false;
    }

    return true;
  }

  void _nextStep() {
    if (_validateCurrentStep() && _currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(colorScheme),
      body:
          _isLoading && !_isInitialized
              ? _buildLoadingState()
              : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMainContent(theme),
              ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      title: Text(
        widget.product == null ? 'Nuevo Producto' : 'Editar Producto',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (widget.product == null)
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: _clearForm,
            tooltip: 'Limpiar formulario',
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando datos...'),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme) {
    return Column(
      children: [
        _buildProgressIndicator(theme.colorScheme),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentStep = index),
            children: [
              _buildBasicInfoStep(),
              _buildPricingStep(),
              _buildFinalDetailsStep(),
            ],
          ),
        ),
        _buildNavigationBar(theme.colorScheme),
      ],
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            icon: Icons.info_outline,
            title: 'Información Básica',
            subtitle: 'Ingrese los datos principales del producto',
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Nombre del producto',
            controller: _nameController,
            prefixIcon: Icons.inventory_2_outlined,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'El nombre es requerido';
              }
              if (_existingProductNames.contains(value!.toLowerCase())) {
                return 'Este nombre ya existe';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Descripción (opcional)',
            controller: _descriptionController,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            icon: Icons.attach_money,
            title: 'Precios',
            subtitle: 'Configure los precios de compra y venta',
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Precio de compra',
            controller: _purchasePriceController,
            prefixIcon: Icons.shopping_cart_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Precio de venta',
            controller: _salePriceController,
            prefixIcon: Icons.sell_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          _buildProfitMarginCard(),
        ],
      ),
    );
  }

  Widget _buildFinalDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            icon: Icons.inventory,
            title: 'Detalles Finales',
            subtitle: 'Complete la información del producto',
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Stock inicial',
            controller: _stockController,
            prefixIcon: Icons.inventory_2_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          _buildSupplierDropdown(),
          const SizedBox(height: 24),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildProfitMarginCard() {
    final purchasePrice = double.tryParse(_purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(_salePriceController.text) ?? 0;
    final margin =
        purchasePrice > 0
            ? ((salePrice - purchasePrice) / purchasePrice * 100)
            : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Margen de Ganancia',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${margin.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: margin > 0 ? Colors.green : Colors.grey,
              ),
            ),
            if (purchasePrice > 0 && salePrice > 0)
              Text(
                'Ganancia: \$${(salePrice - purchasePrice).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierDropdown() {
    return DropdownButtonFormField<Supplier>(
      value: _selectedSupplier,
      decoration: InputDecoration(
        labelText: 'Proveedor',
        prefixIcon: const Icon(Icons.business_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items:
          _suppliers.map((supplier) {
            return DropdownMenuItem(
              value: supplier,
              child: Text('${supplier.names ?? ''} ${supplier.surnames ?? ''}'),
            );
          }).toList(),
      onChanged: (Supplier? value) {
        setState(() => _selectedSupplier = value);
      },
      validator: (value) => value == null ? 'Seleccione un proveedor' : null,
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Nombre', _nameController.text),
            _buildSummaryRow(
              'Precio Compra',
              '\$${_purchasePriceController.text}',
            ),
            _buildSummaryRow('Precio Venta', '\$${_salePriceController.text}'),
            _buildSummaryRow('Stock', _stockController.text),
            _buildSummaryRow(
              'Proveedor',
              _selectedSupplier != null
                  ? '${_selectedSupplier!.names} ${_selectedSupplier!.surnames}'
                  : 'No seleccionado',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'No especificado' : value,
              style: TextStyle(color: value.isEmpty ? Colors.grey : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNavigationBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              child:
                  _currentStep < 2
                      ? FilledButton.icon(
                        onPressed: _nextStep,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Siguiente'),
                      )
                      : FilledButton.icon(
                        onPressed: _isLoading ? null : _saveProduct,
                        icon:
                            _isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.save),
                        label: Text(
                          widget.product == null ? 'Guardar' : 'Actualizar',
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

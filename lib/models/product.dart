import 'supplier.dart';

class Product {
  int? productId;
  String productName;
  String descripcion;
  Supplier supplier; // Usará tu clase completa
  double purchasePrice;
  double salePrice;
  int stock;
  String status;
  String productDate;

  Product({
    this.productId,
    required this.productName,
    required this.descripcion,
    required this.supplier,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    required this.status,
    required this.productDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productId'],
      productName: json['productName'],
      descripcion: json['descripcion'] ?? '',
      supplier: Supplier.fromJson(json['supplier']),
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      salePrice: (json['salePrice'] as num).toDouble(),
      stock: json['stock'],
      status: json['status'],
      productDate: json['productDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'descripcion': descripcion,
      'supplier': supplier.toJson(),
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stock': stock,
      'status': status,
      'productDate': productDate,
    };
  }
}
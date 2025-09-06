class SaleDetail {
  int? saleDetailId;
  int idProduct;
  String productName; // Nueva propiedad para el nombre del producto
  int quantity;
  double price;
  double? total;

  SaleDetail({
    this.saleDetailId,
    required this.idProduct,
    required this.productName, // Inicializamos el nombre del producto
    required this.quantity,
    required this.price,
    this.total,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'saleDetailId': saleDetailId,
      'idProduct': idProduct,
      'productName': productName, // Incluir el nombre del producto en JSON
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  // Crear un SaleDetail a partir de JSON
  factory SaleDetail.fromJson(Map<String, dynamic> json) {
    return SaleDetail(
      saleDetailId: json['saleDetailId'],
      idProduct: json['idProduct'],
      productName:
          json['productName'] ??
          'Producto desconocido', // Asignar nombre del producto
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      total: json['total'] != null ? json['total'].toDouble() : null,
    );
  }
}

class Sale {
  int? saleId;
  int idClient;
  int employeeId;
  String saleDate; // yyyy-MM-dd
  double? total;
  String paymentMethod;
  List<SaleDetail> details;
  bool? isExpanded;

  Sale({
    this.saleId,
    required this.idClient,
    required this.employeeId,
    required this.saleDate,
    this.total,
    required this.paymentMethod,
    required this.details,
    this.isExpanded,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'idClient': idClient,
      'employeeId': employeeId,
      'saleDate': saleDate,
      'total': total,
      'paymentMethod': paymentMethod,
      'details': details.map((e) => e.toJson()).toList(),
      'isExpanded': isExpanded,
    };
  }

  // Crear un Sale a partir de JSON
  factory Sale.fromJson(Map<String, dynamic> json) {
    var detailsFromJson = json['details'] as List;
    List<SaleDetail> detailsList =
        detailsFromJson.map((e) => SaleDetail.fromJson(e)).toList();

    return Sale(
      saleId: json['saleId'],
      idClient: json['idClient'],
      employeeId: json['employeeId'],
      saleDate: json['saleDate'],
      total: json['total'] != null ? json['total'].toDouble() : null,
      paymentMethod: json['paymentMethod'],
      details: detailsList,
      isExpanded: json['isExpanded'],
    );
  }
}

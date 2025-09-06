class Supplier {
  int? idSuppliers;
  String? documentType;
  String? documentNumber;
  String? names;
  String? surnames;
  String? phone;
  String? phone2;
  String? location;
  String? status;
  String? dateBirth;

  Supplier({
    this.idSuppliers,
    this.documentType,
    this.documentNumber,
    this.names,
    this.surnames,
    this.phone,
    this.phone2,
    this.location,
    this.status,
    this.dateBirth,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      idSuppliers: json['idSuppliers'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      names: json['names'],
      surnames: json['surnames'],
      phone: json['phone'],
      phone2: json['phone2'],
      location: json['location'],
      status: json['status'],
      dateBirth: json['dateBirth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idSuppliers': idSuppliers,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'names': names,
      'surnames': surnames,
      'phone': phone,
      'phone2': phone2,
      'location': location,
      'status': status,
      'dateBirth': dateBirth,
    };
  }
}
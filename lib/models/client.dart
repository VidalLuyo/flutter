class Client {
  int? idClient;
  String documentType;
  String documentNumber;
  String firstName;
  String lastName;
  String
  birthDate; // ISO string (yyyy-MM-dd) para compatibilidad con los inputs de fecha de HTML
  String gmail;
  String phone;
  String? phone2;
  String? location;
  String? status;
  String? registerDate;

  Client({
    this.idClient,
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gmail,
    required this.phone,
    this.phone2,
    this.location,
    this.status,
    this.registerDate,
  });

  // Método para convertir un objeto Client a un mapa de datos JSON
  Map<String, dynamic> toJson() {
    return {
      'idClient': idClient,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate,
      'gmail': gmail,
      'phone': phone,
      'phone2': phone2,
      'location': location,
      'status': status,
      'registerDate': registerDate,
    };
  }

  // Método para crear un objeto Client a partir de un mapa de datos JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      idClient: json['idClient'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      birthDate: json['birthDate'],
      gmail: json['gmail'],
      phone: json['phone'],
      phone2: json['phone2'],
      location: json['location'],
      status: json['status'],
      registerDate: json['registerDate'],
    );
  }
}

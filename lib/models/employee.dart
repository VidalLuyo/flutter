// Modelo que representa a un empleado y se usa para la comunicación con la API
class Employee {
  final int? employeeId;
  final String documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String? email;
  final String? phone;
  final String? address;
  final String role;
  final String? status;

  Employee({
    this.employeeId,
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.email,
    this.phone,
    this.address,
    required this.role,
    this.status,
  });

  // Crea un objeto Employee desde un JSON recibido del backend
  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        employeeId: json['employeeId'],
        documentType: json['documentType'],
        documentNumber: json['documentNumber'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        birthDate: json['birthDate'],
        email: json['email'],
        phone: json['phone'],
        address: json['address'],
        role: json['role'],
        status: json['status'],
      );

  // Convierte un objeto Employee a JSON para enviarlo al backend
  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'email': email,
        'phone': phone,
        'address': address,
        'role': role,
        'status': status,
      };

  // Crea una copia del objeto actual pero con valores actualizados
  Employee copyWith({
    String? documentType,
    String? documentNumber,
    String? firstName,
    String? lastName,
    String? birthDate,
    String? email,
    String? phone,
    String? address,
    String? role,
    String? status,
  }) {
    return Employee(
      employeeId: employeeId,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }
}

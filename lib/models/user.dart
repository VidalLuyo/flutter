class User {
  int? userId;
  String username;
  String password;
  String role;
  String? state;

  User({
    this.userId,
    required this.username,
    required this.password,
    required this.role,
    this.state,
  });

  // Método para convertir el JSON a un objeto User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
      state: json['state'],
    );
  }

  // Método para convertir el objeto User a JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'password': password,
      'role': role,
      'state': state,
    };
  }
}

class User {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role;
  final String? phone;
  final String? department;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.phone,
    this.department,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employe',
      phone: json['phone'],
      department: json['department'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'phone': phone,
      'department': department,
    };
  }

  String get fullName => '$prenom $nom';
}

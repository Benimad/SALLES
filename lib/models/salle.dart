class Salle {
  final int id;
  final String nom;
  final int capacite;
  final String equipements;
  final bool disponible;

  Salle({
    required this.id,
    required this.nom,
    required this.capacite,
    required this.equipements,
    this.disponible = true,
  });

  factory Salle.fromJson(Map<String, dynamic> json) {
    return Salle(
      id: int.parse(json['id'].toString()),
      nom: json['nom'] ?? '',
      capacite: int.parse(json['capacite'].toString()),
      equipements: json['equipements'] ?? '',
      disponible: json['disponible'] == 1 || json['disponible'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'capacite': capacite,
      'equipements': equipements,
      'disponible': disponible ? 1 : 0,
    };
  }
}

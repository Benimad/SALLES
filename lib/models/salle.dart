class Salle {
  final int id;
  final String nom;
  final int capacite;
  final int? etage;
  final String? localisation;
  final String equipements;
  final bool disponible;
  final String? description;
  final String? contactResponsable;

  Salle({
    required this.id,
    required this.nom,
    required this.capacite,
    this.etage,
    this.localisation,
    required this.equipements,
    this.disponible = true,
    this.description,
    this.contactResponsable,
  });

  factory Salle.fromJson(Map<String, dynamic> json) {
    return Salle(
      id: int.parse(json['id'].toString()),
      nom: json['nom'] ?? '',
      capacite: int.parse(json['capacite'].toString()),
      etage: json['etage'] != null ? int.tryParse(json['etage'].toString()) : null,
      localisation: json['localisation'],
      equipements: json['equipements'] ?? '',
      disponible: json['disponible'] == 1 || json['disponible'] == true || json['disponible'] == '1',
      description: json['description'],
      contactResponsable: json['contact_responsable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'capacite': capacite,
      'etage': etage,
      'localisation': localisation,
      'equipements': equipements,
      'disponible': disponible ? 1 : 0,
      'description': description,
      'contact_responsable': contactResponsable,
    };
  }
}

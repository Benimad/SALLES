class Salle {
  final String id;
  final String nom;
  final int capacite;
  final int? etage;
  final String? localisation;
  final String equipements;
  final bool disponible;
  final String? description;
  final String? contactResponsable;
  final String? imageUrl;

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
    this.imageUrl,
  });

  factory Salle.fromJson(Map<String, dynamic> json) {
    return Salle(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      capacite: int.tryParse(json['capacite']?.toString() ?? '0') ?? 0,
      etage: json['etage'] != null ? int.tryParse(json['etage'].toString()) : null,
      localisation: json['localisation'],
      equipements: json['equipements'] ?? '',
      disponible: json['disponible'] == true || json['disponible'] == 1 || json['disponible'] == '1',
      description: json['description'],
      contactResponsable: json['contact_responsable'],
      imageUrl: json['image_url'],
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
      'disponible': disponible,
      'description': description,
      'contact_responsable': contactResponsable,
      'image_url': imageUrl,
    };
  }
}

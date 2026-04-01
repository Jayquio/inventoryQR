class Instrument {
  final String type;
  final String name;
  final String? serialNumber;
  final String category;
  final int quantity;
  int available;
  final String status;
  final String condition;
  final String location;
  final String lastMaintenance;
  final String? imageAsset;

  Instrument({
    this.type = 'instrument',
    required this.name,
    this.serialNumber,
    required this.category,
    required this.quantity,
    required this.available,
    required this.status,
    required this.condition,
    required this.location,
    required this.lastMaintenance,
    this.imageAsset,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      type: (json['type'] ?? 'instrument') as String,
      name: json['name'] as String,
      serialNumber: json['serialNumber'] as String?,
      category: (json['category'] ?? '') as String,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      available: int.tryParse(json['available']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? '') as String,
      condition: (json['condition'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      lastMaintenance: (json['lastMaintenance'] ?? '') as String,
      imageAsset: json['imageAsset'] as String?,
    );
    }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      if (serialNumber != null) 'serialNumber': serialNumber,
      'category': category,
      'quantity': quantity,
      'available': available,
      'status': status,
      'condition': condition,
      'location': location,
      'lastMaintenance': lastMaintenance,
      if (imageAsset != null) 'imageAsset': imageAsset,
    };
  }
}

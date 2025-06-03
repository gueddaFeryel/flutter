class OperatingRoom {
  final int id;
  final String name;
  final String location;
  final String category;
  final String? equipment;

  OperatingRoom({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    this.equipment,
  });

  factory OperatingRoom.fromJson(Map<String, dynamic> json) {
    return OperatingRoom(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      category: json['category'] as String,
      equipment: json['equipment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'category': category,
      'equipment': equipment,
    };
  }
}
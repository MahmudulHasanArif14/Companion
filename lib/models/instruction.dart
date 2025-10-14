class Instruction {
  final String text;
  final double distance;
  final double lat;
  final double lng;

  Instruction({
    required this.text,
    required this.distance,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'distance': distance,
    'lat': lat,
    'lng': lng,
  };

  factory Instruction.fromJson(Map<String, dynamic> json) => Instruction(
    text: json['text'],
    distance: (json['distance'] ?? 0).toDouble(),
    lat: (json['lat'] ?? 0).toDouble(),
    lng: (json['lng'] ?? 0).toDouble(),
  );
}

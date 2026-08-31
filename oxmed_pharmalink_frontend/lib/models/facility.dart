class Facility {
  final String name;
  final double distance;
  final int travelTime;
  final bool isAvailable;

  Facility({
    required this.name,
    required this.distance,
    required this.travelTime,
    this.isAvailable = true,
  });
}
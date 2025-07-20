class Person {
  final String id;
  final String name;
  final String fatherName;
  final String motherName;
  final String grandfatherName;
  final String notes;
  bool isimp;
  final List<String> children;

  Person({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.motherName,
    required this.grandfatherName,
    required this.notes,
    required this.isimp,
    this.children = const [],
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      grandfatherName: json['grandfatherName'] ?? '',
      notes: json['notes'] ?? '',
      isimp: json['isimp'] ?? false,
      children: (json['children'] is List)
          ? List<String>.from(json['children'] ?? [])
          : [],
    );
  }
}

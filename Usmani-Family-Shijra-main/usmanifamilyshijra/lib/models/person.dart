class Person {
  final String id;
  final String name;
  final String fatherName;
  final String motherName;
  final List<String> children;  // Adding the children property

  Person({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.motherName,
    this.children = const [],  // Default empty list if no children are provided
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      children: json['children'] != null
          ? List<String>.from(json['children'])
          : [],  // Ensure the children property is properly parsed
    );
  }
}

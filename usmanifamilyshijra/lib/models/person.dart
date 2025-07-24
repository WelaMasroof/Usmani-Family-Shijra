class Person {
  final String id;
  final String name;
  final String fatherName;

  Person({
    required this.id,
    required this.name,
    required this.fatherName,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      name: json['name'],
      fatherName: json['fatherName'] ?? '',
    );
  }
}

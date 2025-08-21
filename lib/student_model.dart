class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String email;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.email,
  });

  factory Student.fromMap(Map map, String docId) {
    return Student(
      id: docId,
      name: map['name'],
      rollNumber: map['rollNumber'],
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
    };
  }
}

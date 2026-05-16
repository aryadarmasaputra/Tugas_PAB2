class Course {
  final String id;
  final String name;
  final String lecturer;

  Course({required this.id, required this.name, required this.lecturer});

  /// Membuat objek Course dari data Firebase Realtime Database
  factory Course.fromMap(String id, Map<dynamic, dynamic> map) {
    return Course(
      id: id,
      name: map['name'] as String? ?? '',
      lecturer: map['lecturer'] as String? ?? '',
    );
  }

  /// Mengubah objek Course menjadi Map untuk disimpan ke Firebase
  Map<String, dynamic> toMap() {
    return {'name': name, 'lecturer': lecturer};
  }

  @override
  String toString() => name;
}

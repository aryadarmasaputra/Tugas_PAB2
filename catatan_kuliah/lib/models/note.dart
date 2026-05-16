class Note {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String content;
  final int timestamp;

  Note({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.content,
    required this.timestamp,
  });

  factory Note.fromMap(String id, Map<dynamic, dynamic> map) {
    return Note(
      id: id,
      courseId: map['courseId'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'content': content,
      'timestamp': timestamp,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

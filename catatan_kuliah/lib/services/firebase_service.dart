import 'package:catatan_kuliah/models/course.dart';
import 'package:catatan_kuliah/models/note.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/course.dart';
import 'package:catatan_kuliah/models/note.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Stream<List<Course>> getCourses() {
    return _db.child('courses').orderByChild('name').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      final courses = map.entries
          .map(
            (e) => Course.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)),
          )
          .toList();
      courses.sort((a, b) => a.name.compareTo(b.name));
      return courses;
    });
  }

  Future<void> addCourse(Course course) async {
    await _db.child('courses').push().set(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _db.child('courses').child(id).remove();
  }

  Stream<List<Note>> getNotes() {
    return _db.child('notes').orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];
      final map = Map<String, dynamic>.from(data as Map);
      final notes = map.entries
          .map((e) => Note.fromMap(e.key, Map<dynamic, dynamic>.from(e.value)))
          .toList();
      notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notes;
    });
  }

  Future<void> addNote(Note note) async {
    await _db.child('notes').push().set(note.toMap());
  }

  Future<void> updateNote(String id, Note note) async {
    await _db.child('notes').child(id).update(note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _db.child('notes').child(id).remove();
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/note.dart';
import '../services/firebase_service.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? noteToEdit;
  const AddNoteScreen({super.key, this.noteToEdit});
  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final FirebaseService _service = FirebaseService();

  bool _isSaving = false;
  bool _isLoadingCourses = true;
  List<Course> _courses = [];
  Course? _selectedCourse;

  bool get _isEditMode => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    if (_isEditMode) {
      _titleController.text = widget.noteToEdit!.title;
      _contentController.text = widget.noteToEdit!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    _service
        .getCourses()
        .first
        .then((courses) {
          if (!mounted) return;
          setState(() {
            _courses = courses;
            _isLoadingCourses = false;
            // Pilih kembali mata kuliah yang sesuai saat edit mode
            if (_isEditMode && courses.isNotEmpty) {
              _selectedCourse = courses.firstWhere(
                (c) => c.id == widget.noteToEdit!.courseId,
                orElse: () => courses.first,
              );
            }
          });
        })
        .catchError((e) {
          if (mounted) setState(() => _isLoadingCourses = false);
        });
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final note = Note(
        id: _isEditMode ? widget.noteToEdit!.id : '',
        courseId: _selectedCourse!.id,
        courseName: _selectedCourse!.name,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        timestamp: _isEditMode ? widget.noteToEdit!.timestamp : now,
      );

      if (_isEditMode) {
        await _service.updateNote(note.id, note);
      } else {
        await _service.addNote(note);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Catatan berhasil diperbarui!'
                : 'Catatan berhasil disimpan!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Tambah Catatan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(widget.noteToEdit!.dateTime)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              _isLoadingCourses
                  ? const Center(child: CircularProgressIndicator())
                  : _courses.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Belum ada mata kuliah. Tambahkan dahulu di menu "Mata Kuliah".',
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<Course>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Mata Kuliah',
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Pilih mata kuliah'),
                      items: _courses
                          .map(
                            (course) => DropdownMenuItem<Course>(
                              value: course,
                              child: Text(
                                course.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCourse = value);
                      },
                      validator: (value) {
                        if (value == null) return 'Pilih mata kuliah';
                        return null;
                      },
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Contoh: Pertemuan 1 – Pengenalan Flutter',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul catatan tidak boleh kosong';
                  }
                  if (value.trim().length < 3) {
                    return 'Judul minimal 3 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tulis catatan kuliah di sini...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 128),
                    child: Icon(Icons.notes),
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Isi catatan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan Catatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

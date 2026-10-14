import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/book_service.dart';

class BookFormPage extends StatefulWidget {
  final Map<String, dynamic>? book;

  const BookFormPage({super.key, this.book});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final publisherController = TextEditingController();
  final categoryController = TextEditingController();
  final stockController = TextEditingController();
  final shelfController = TextEditingController();

  final imagePicker = ImagePicker();

  String? imagePath;
  bool isSaving = false;

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();

    final book = widget.book;
    if (book != null) {
      titleController.text = book['title']?.toString() ?? '';
      authorController.text = book['author']?.toString() ?? '';
      publisherController.text = book['publisher']?.toString() ?? '';
      categoryController.text = book['category']?.toString() ?? '';
      stockController.text = book['stock_total']?.toString() ?? '0';
      shelfController.text = book['shelf']?.toString() ?? '';
    } else {
      stockController.text = '1';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    publisherController.dispose();
    categoryController.dispose();
    stockController.dispose();
    shelfController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked != null && mounted) {
        setState(() => imagePath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        showMessage('Gagal memilih gambar: $e');
      }
    }
  }

  Future<void> saveBook() async {
    if (!formKey.currentState!.validate()) return;

    final token = AuthService.token;
    if (token == null) {
      showMessage('Sesi login tidak ditemukan. Silakan login ulang.');
      return;
    }

    final stock = int.tryParse(stockController.text.trim());
    if (stock == null || stock < 0) {
      showMessage('Jumlah stok harus berupa angka minimal 0.');
      return;
    }

    setState(() => isSaving = true);

    try {
      if (isEditing) {
        await BookService.updateBook(
          token: token,
          id: int.parse(widget.book!['id'].toString()),
          title: titleController.text.trim(),
          author: authorController.text.trim(),
          publisher: publisherController.text.trim(),
          category: categoryController.text.trim(),
          stockTotal: stock,
          shelf: shelfController.text.trim(),
          imagePath: imagePath,
        );
      } else {
        await BookService.createBook(
          token: token,
          title: titleController.text.trim(),
          author: authorController.text.trim(),
          publisher: publisherController.text.trim(),
          category: categoryController.text.trim(),
          stockTotal: stock,
          shelf: shelfController.text.trim(),
          imagePath: imagePath,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Buku berhasil diperbarui.'
                : 'Buku berhasil ditambahkan.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label wajib diisi.';
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingCover = widget.book?['cover_url']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Buku' : 'Tambah Buku'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: InkWell(
                  onTap: pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 150,
                    height: 190,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imagePath != null
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                          )
                        : existingCover != null &&
                                existingCover.isNotEmpty
                            ? Image.network(
                                existingCover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                ),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: Color(0xFF2563EB),
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ketuk gambar untuk memilih sampul buku (opsional).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              buildField(
                label: 'Judul Buku',
                controller: titleController,
                icon: Icons.menu_book_outlined,
                requiredField: true,
              ),
              buildField(
                label: 'Penulis',
                controller: authorController,
                icon: Icons.person_outline,
                requiredField: true,
              ),
              buildField(
                label: 'Penerbit',
                controller: publisherController,
                icon: Icons.business_outlined,
              ),
              buildField(
                label: 'Kategori',
                controller: categoryController,
                icon: Icons.category_outlined,
              ),
              buildField(
                label: 'Jumlah Stok',
                controller: stockController,
                icon: Icons.inventory_2_outlined,
                requiredField: true,
                keyboardType: TextInputType.number,
              ),
              buildField(
                label: 'Lokasi Rak',
                controller: shelfController,
                icon: Icons.shelves,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : saveBook,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isSaving ? 'Menyimpan...' : 'Simpan Buku',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../katalog.dart';

class BorrowDialog extends StatefulWidget {
  final Book book;

  const BorrowDialog({super.key, required this.book});

  @override
  State<BorrowDialog> createState() => _BorrowDialogState();
}

class _BorrowDialogState extends State<BorrowDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal kembali')),
      );
      return;
    }

    final quantity = int.parse(_quantityController.text.trim());
    Navigator.of(
      context,
    ).pop(BorrowRequest(quantity: quantity, dueDate: _selectedDate!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Konfirmasi Peminjaman'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.book.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah buku'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                final n = int.tryParse(value);
                if (n == null || n <= 0) {
                  return 'Jumlah tidak valid';
                }
                if (n > widget.book.stockRemaining) {
                  return 'Jumlah melebihi stok';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal kembali',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Pilih tanggal'
                          : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                    ),
                    const Icon(Icons.date_range_outlined),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A3BA9),
            foregroundColor: Colors.white,
          ),
          child: const Text('Pinjam'),
        ),
      ],
    );
  }
}

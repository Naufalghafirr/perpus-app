import 'package:flutter/material.dart';

import '../service/api_client.dart';

class RegisterPage extends StatefulWidget {
  final ApiClient apiClient;

  const RegisterPage({super.key, required this.apiClient});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.apiClient.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _success = 'Register berhasil, silakan login';
      });

      // Navigate back to login after successful registration
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SizedBox(
        height: screenHeight,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        screenHeight -
                        (keyboardHeight > 0 ? keyboardHeight : 0),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: screenHeight * 0.25,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: SafeArea(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Buat Akun Baru',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Daftar untuk mengakses perpustakaan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nama lengkap',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF64748B),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Nama tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Color(0xFF64748B),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email tidak boleh kosong';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Format email tidak valid';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: Color(0xFF64748B),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (value.length < 4) {
                                          return 'Minimal 4 karakter';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (_error != null)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFEF4444),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: const TextStyle(
                                                color: Color(0xFFEF4444),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (_success != null)
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Color(0xFF16A34A),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _success!,
                                              style: const TextStyle(
                                                color: Color(0xFF16A34A),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF1A3BA9,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Daftar',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Sudah punya akun? ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF1A3BA9),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

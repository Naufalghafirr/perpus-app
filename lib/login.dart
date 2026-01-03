import 'package:flutter/material.dart';

import 'service/api_client.dart';
import 'models/user_profile.dart';
import 'models/auth_result.dart';
import 'modals/register.dart';
import 'register_page.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile? user;
  final ApiClient apiClient;
  final Future<void> Function() onLogout;
  final Future<void> Function(AuthResult result) onLoggedIn;
  final Future<void> Function(UserProfile updatedUser) onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.user,
    required this.apiClient,
    required this.onLogout,
    required this.onLoggedIn,
    required this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _loginLoading = false;
  String? _loginError;
  bool _rememberMe = true;

  bool _profileSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user?.name ?? '';
    _emailController.text = widget.user?.email ?? '';
    _phoneController.text = widget.user?.phone_number ?? '';
    _addressController.text = widget.user?.address ?? '';
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user?.name != oldWidget.user?.name ||
        widget.user?.email != oldWidget.user?.email ||
        widget.user?.phone_number != oldWidget.user?.phone_number ||
        widget.user?.address != oldWidget.user?.address) {
      _nameController.text = widget.user?.name ?? '';
      _emailController.text = widget.user?.email ?? '';
      _phoneController.text = widget.user?.phone_number ?? '';
      _addressController.text = widget.user?.address ?? '';
    }
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _loginLoading = true;
      _loginError = null;
    });

    try {
      final messenger = ScaffoldMessenger.of(context);
      final result = await widget.apiClient.login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      await widget.onLoggedIn(result);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Berhasil login')));
    } catch (e) {
      setState(() {
        _loginError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loginLoading = false;
        });
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (widget.user == null) return;

    setState(() {
      _profileSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    final updated = UserProfile(
      id: widget.user!.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone_number: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );

    try {
      await widget.onProfileUpdated(updated);

      if (!mounted) return;

      setState(() {
        _profileSaving = false;
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Profil berhasil disimpan')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profileSaving = false;
      });

      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = widget.user != null;
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
                        height: isLoggedIn
                            ? screenHeight * 0.25
                            : screenHeight * 0.35,
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
                                  width: isLoggedIn ? 60 : 80,
                                  height: isLoggedIn ? 60 : 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isLoggedIn
                                          ? Icons.person_rounded
                                          : Icons.menu_book_rounded,
                                      color: Colors.white,
                                      size: isLoggedIn ? 30 : 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isLoggedIn
                                      ? 'Profil Saya'
                                      : 'Perpustakaan Digital',
                                  style: TextStyle(
                                    fontSize: isLoggedIn ? 20 : 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if (!isLoggedIn) ...[
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Akses ribuan buku dalam genggaman',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -40),
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
                            padding: EdgeInsets.fromLTRB(
                              24,
                              32,
                              24,
                              isLoggedIn ? 32 : 20,
                            ),
                            child: !isLoggedIn
                                ? _buildLoginCard(context)
                                : _buildProfileCard(context),
                          ),
                        ),
                      ),
                      if (!isLoggedIn) const SizedBox(height: 40),
                      if (isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await widget.onLogout();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Berhasil logout'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Keluar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (!isLoggedIn) const SizedBox(height: 20),
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

  Widget _buildLoginCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selamat Datang Kembali',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Masuk ke akun perpustakaan Anda',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
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
                    if (value == null || value.trim().isEmpty) {
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _rememberMe
                                ? const Color(0xFF1A3BA9)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _rememberMe
                                  ? const Color(0xFF1A3BA9)
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Ingat saya',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A3BA9),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_loginError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
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
                            _loginError!,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loginLoading ? null : _submitLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3BA9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loginLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Masuk',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RegisterPage(apiClient: widget.apiClient),
                        ),
                      );
                    },
                    child: const Text(
                      'Daftar sekarang',
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
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3BA9), Color(0xFF4F70FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user?.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Form(
          key: _profileFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!value.contains('@')) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
                    prefixIcon: Icon(
                      Icons.home_outlined,
                      color: Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _profileSaving ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3BA9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _profileSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthDialog extends StatelessWidget {
  final ApiClient apiClient;

  const AuthDialog({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Masuk',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Login untuk melanjutkan peminjaman buku',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: LoginForm(
                apiClient: apiClient,
                onSuccess: (result) {
                  Navigator.of(context).pop(result);
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: SizedBox(
                              width: 360,
                              height: 460,
                              child: RegisterForm(apiClient: apiClient),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Daftar sekarang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final ApiClient apiClient;
  final void Function(AuthResult result) onSuccess;

  const LoginForm({
    super.key,
    required this.apiClient,
    required this.onSuccess,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.apiClient.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      widget.onSuccess(result);
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!value.contains('@')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
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
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3BA9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
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
                      : const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

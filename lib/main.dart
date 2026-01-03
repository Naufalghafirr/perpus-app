import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard.dart';
import 'katalog.dart';
import 'riwayat.dart';
import 'pages/account_page.dart';
import 'modals/pinjam.dart';
import 'service/api_client.dart';
import 'models/user_profile.dart';
import 'models/auth_result.dart';
import 'models/book.dart';

void main() {
  runApp(const LibraryApp());
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3BA9)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient apiClient = ApiClient();
  int selectedIndex = 1;
  String? token;
  UserProfile? user;
  bool loadingSession = true;
  final List<int> _tabVersions = [0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('authToken');
    final savedName = prefs.getString('userName');
    final savedEmail = prefs.getString('userEmail');
    final savedPhone = prefs.getString('userPhone');
    final savedAddress = prefs.getString('userAddress');
    final savedRole = prefs.getString('userRole');
    setState(() {
      token = savedToken;
      if (savedName != null && savedEmail != null) {
        user = UserProfile(
          name: savedName,
          email: savedEmail,
          phone_number: savedPhone,
          address: savedAddress,
          role: savedRole ?? 'user',
        );
      }
      loadingSession = false;
    });
  }

  Future<void> _saveSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', result.token);
    await prefs.setString('userName', result.user.name);
    await prefs.setString('userEmail', result.user.email);
    await prefs.setString('userRole', result.user.role);
    if (result.user.phone_number != null) {
      await prefs.setString('userPhone', result.user.phone_number!);
    } else {
      await prefs.remove('userPhone');
    }
    if (result.user.address != null) {
      await prefs.setString('userAddress', result.user.address!);
    } else {
      await prefs.remove('userAddress');
    }
    setState(() {
      token = result.token;
      user = result.user;
    });
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('userAddress');
    await prefs.remove('userRole');
    setState(() {
      token = null;
      user = null;
    });
  }

  Future<bool> _handleBorrow(Book book) async {
    if (token == null) {
      // Navigate to login tab
      setState(() {
        selectedIndex = 3; // Account tab
      });
      return false;
    }

    if (!mounted) return false;

    final borrowData = await showDialog<BorrowRequest?>(
      context: context,
      builder: (context) {
        return BorrowDialog(book: book);
      },
    );

    if (borrowData == null) return false;

    if (!mounted) return false;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    try {
      await apiClient.borrowBook(
        token: token!,
        bookId: book.id,
        quantity: borrowData.quantity,
        dueDate: borrowData.dueDate,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Peminjaman berhasil')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (loadingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user?.role == 'administrator';

    final pages = [
      DashboardPage(
        key: ValueKey('dashboard-${_tabVersions[0]}'),
        user: user,
        apiClient: apiClient,
        token: token,
      ),
      CatalogPage(
        key: ValueKey('catalog-${_tabVersions[1]}'),
        apiClient: apiClient,
        onBorrow: _handleBorrow,
        isAdmin: isAdmin,
        token: token,
      ),
      HistoryPage(
        key: ValueKey('history-${_tabVersions[2]}'),
        apiClient: apiClient,
        token: token,
        isAdmin: isAdmin,
      ),
      AccountPage(
        key: ValueKey('account-${_tabVersions[3]}'),
        user: user,
        apiClient: apiClient,
        token: token,
        onLoggedIn: _saveSession,
        onProfileUpdated: _updateUser,
        onLogout: _clearSession,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            _tabVersions[index] = _tabVersions[index] + 1;
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A3BA9),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            label: isAdmin ? 'Kelola Buku' : 'Katalog',
          ),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.keyboard_return : Icons.history),
            label: isAdmin ? 'Pengembalian' : 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Future<void> _updateUser(UserProfile updatedUser) async {
    if (token == null) {
      throw Exception('Anda belum login');
    }

    final serverUser = await apiClient.updateProfile(
      token: token!,
      name: updatedUser.name,
      email: updatedUser.email,
      phone_number: updatedUser.phone_number,
      address: updatedUser.address,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', serverUser.name);
    await prefs.setString('userEmail', serverUser.email);
    await prefs.setString('userRole', serverUser.role);
    if (serverUser.phone_number != null &&
        serverUser.phone_number!.isNotEmpty) {
      await prefs.setString('userPhone', serverUser.phone_number!);
    } else {
      await prefs.remove('userPhone');
    }
    if (serverUser.address != null && serverUser.address!.isNotEmpty) {
      await prefs.setString('userAddress', serverUser.address!);
    } else {
      await prefs.remove('userAddress');
    }
    setState(() {
      user = serverUser;
    });
  }
}

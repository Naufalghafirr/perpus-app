import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/book.dart';
import '../models/paginated_books.dart';
import '../models/loan_relations.dart';
import '../models/user_profile.dart';
import '../models/auth_result.dart';

class ApiClient {
  final String baseUrl = getBaseUrl();

  Future<PaginatedBooksResponse> getBooks({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/books?page=$page&limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat buku (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Respons tidak valid');
    }

    return PaginatedBooksResponse.fromJson(data);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Login gagal');
      } catch (_) {
        throw Exception('Login gagal (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    return AuthResult(token: token, user: user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Register gagal');
      } catch (_) {
        throw Exception('Register gagal (${response.statusCode})');
      }
    }
  }

  Future<void> borrowBook({
    required String token,
    required int bookId,
    required int quantity,
    required DateTime dueDate,
  }) async {
    final uri = Uri.parse('$baseUrl/api/books');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bookId': bookId,
        'quantity': quantity,
        'dueDate':
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      }),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Peminjaman gagal');
      } catch (_) {
        throw Exception('Peminjaman gagal (${response.statusCode})');
      }
    }
  }

  Future<PaginatedBooksResponse> getAdminBooks({
    required String token,
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/books?page=$page&limit=$limit');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal memuat buku');
      } catch (_) {
        throw Exception('Gagal memuat buku (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Respons tidak valid');
    }

    return PaginatedBooksResponse.fromJson(data);
  }

  Future<Book> createBook({
    required String token,
    required String title,
    required String writer,
    required String publisher,
    required int year,
    required String isbn,
    required int stock,
    String? description,
    String? coverImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/books');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'writer': writer,
        'publisher': publisher,
        'year': year,
        'isbn': isbn,
        'total_stock': stock,
        'stock_remaining': stock,
        'description': description,
        'cover_image': coverImage,
      }),
    );

    if (response.statusCode != 201) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal menambah buku');
      } catch (_) {
        throw Exception('Gagal menambah buku (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bookJson = data['book'] as Map<String, dynamic>;
    return Book.fromJson(bookJson);
  }

  Future<Book> updateBook({
    required String token,
    required int id,
    required String title,
    required String writer,
    required String publisher,
    required int year,
    required String isbn,
    required int stock,
    String? description,
    String? coverImage,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/books');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': id,
        'title': title,
        'writer': writer,
        'publisher': publisher,
        'year': year,
        'isbn': isbn,
        'total_stock': stock,
        'stock_remaining': stock,
        'description': description,
        'cover_image': coverImage,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal mengubah buku');
      } catch (_) {
        throw Exception('Gagal mengubah buku (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bookJson = data['book'] as Map<String, dynamic>;
    return Book.fromJson(bookJson);
  }

  Future<void> deleteBook({required String token, required int id}) async {
    final uri = Uri.parse('$baseUrl/api/admin/books');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal menghapus buku');
      } catch (_) {
        throw Exception('Gagal menghapus buku (${response.statusCode})');
      }
    }
  }

  Future<void> markLoanReturned({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/api/loans/$id');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          data['error'] ??
              data['message'] ??
              'Gagal mengubah status peminjaman',
        );
      } catch (_) {
        throw Exception(
          'Gagal mengubah status peminjaman (${response.statusCode})',
        );
      }
    }
  }

  Future<UserProfile> updateProfile({
    required String token,
    required String name,
    required String email,
    String? phone_number,
    String? address,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/profile');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone_number': phone_number,
        'address': address,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Update profil gagal');
      } catch (_) {
        throw Exception('Update profil gagal (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userJson);
  }

  // New methods for loans with relationships
  Future<PaginatedLoansResponse> getLoans({
    required String token,
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(
      '$baseUrl/api/loans',
    ).replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          data['error'] ?? data['message'] ?? 'Gagal memuat riwayat peminjaman',
        );
      } catch (_) {
        throw Exception(
          'Gagal memuat riwayat peminjaman (${response.statusCode})',
        );
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Handle the response format from your API
    final loansData = data['data'] as List<dynamic>? ?? [];
    final loans = loansData
        .map(
          (loanJson) =>
              LoanWithRelations.fromJson(loanJson as Map<String, dynamic>),
        )
        .toList();

    final paginationData = data['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedLoansResponse(loans: loans, pagination: pagination);
  }

  Future<PaginatedLoansResponse> getAdminLoans({
    required String token,
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }

    final uri = Uri.parse(
      '$baseUrl/api/admin/loans',
    ).replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(
          data['error'] ??
              data['message'] ??
              'Gagal memuat riwayat peminjaman admin',
        );
      } catch (_) {
        throw Exception(
          'Gagal memuat riwayat peminjaman admin (${response.statusCode})',
        );
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Handle the response format from your API
    final loansData = data['data'] as List<dynamic>? ?? [];
    final loans = loansData
        .map(
          (loanJson) =>
              LoanWithRelations.fromJson(loanJson as Map<String, dynamic>),
        )
        .toList();

    final paginationData = data['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedLoansResponse(loans: loans, pagination: pagination);
  }

  Future<LoanWithRelations> createAdminLoan({
    required String token,
    required int bookId,
    required int userId,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/loans');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'book_id': bookId, 'user_id': userId, 'notes': notes}),
    );

    if (response.statusCode != 201) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal membuat peminjaman');
      } catch (_) {
        throw Exception('Gagal membuat peminjaman (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final loanJson = data['data'] as Map<String, dynamic>;
    return LoanWithRelations.fromJson(loanJson);
  }

  Future<LoanWithRelations> updateAdminLoan({
    required String token,
    required int id,
    String? status,
    String? returnDate,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/loans');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': id,
        'status': status,
        'return_date': returnDate,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal mengubah peminjaman');
      } catch (_) {
        throw Exception('Gagal mengubah peminjaman (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final loanJson = data['data'] as Map<String, dynamic>;
    return LoanWithRelations.fromJson(loanJson);
  }

  Future<void> deleteAdminLoan({required String token, required int id}) async {
    final uri = Uri.parse('$baseUrl/api/admin/loans');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal menghapus peminjaman');
      } catch (_) {
        throw Exception('Gagal menghapus peminjaman (${response.statusCode})');
      }
    }
  }

  Future<PaginatedUsersResponse> getAdminUsers({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/users?page=$page&limit=$limit');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal memuat pengguna');
      } catch (_) {
        throw Exception('Gagal memuat pengguna (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception('Respons tidak valid');
    }

    final usersData = data['data'] as List<dynamic>? ?? [];
    final users = usersData
        .map(
          (userJson) => UserProfile.fromJson(userJson as Map<String, dynamic>),
        )
        .toList();

    final paginationData = data['pagination'] as Map<String, dynamic>? ?? {};
    final pagination = Pagination.fromJson(paginationData);

    return PaginatedUsersResponse(users: users, pagination: pagination);
  }

  Future<UserProfile> createAdminUser({
    required String token,
    required String name,
    required String email,
    required String password,
    String? role,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/users');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role ?? 'user',
      }),
    );

    if (response.statusCode != 201) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal membuat pengguna');
      } catch (_) {
        throw Exception('Gagal membuat pengguna (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userJson);
  }

  Future<UserProfile> updateAdminUser({
    required String token,
    required int id,
    required String name,
    required String email,
    String? role,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/users');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id, 'name': name, 'email': email, 'role': role}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal mengubah pengguna');
      } catch (_) {
        throw Exception('Gagal mengubah pengguna (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userJson);
  }

  Future<void> deleteAdminUser({required String token, required int id}) async {
    final uri = Uri.parse('$baseUrl/api/admin/users');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal menghapus pengguna');
      } catch (_) {
        throw Exception('Gagal menghapus pengguna (${response.statusCode})');
      }
    }
  }

  Future<LoanWithRelations> returnAdminLoan({
    required String token,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/loans');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'id': id}),
    );

    if (response.statusCode != 200) {
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(data['message'] ?? 'Gagal mengembalikan buku');
      } catch (_) {
        throw Exception('Gagal mengembalikan buku (${response.statusCode})');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final loanJson = data['data'] as Map<String, dynamic>;
    return LoanWithRelations.fromJson(loanJson);
  }
}

class UserProfile {
  final int? id;
  final String name;
  final String email;
  final String? phone_number;
  final String? address;
  final String role;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.phone_number,
    this.address,
    this.role = 'user',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone_number: json['phone_number'] as String?,
      address: json['address'] as String?,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phone_number,
      'address': address,
      'role': role,
    };
  }
}

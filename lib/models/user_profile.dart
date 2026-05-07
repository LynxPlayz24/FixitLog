import 'dart:convert';

class UserProfile {
  final String email;
  String fullName;
  DateTime? birthdate;
  String address;
  String phoneNumber;
  String? profileImageBase64;

  UserProfile({
    required this.email,
    this.fullName = '',
    this.birthdate,
    this.address = '',
    this.phoneNumber = '',
    this.profileImageBase64,
  });

  /// Calculated age from birthdate.
  int? get age {
    if (birthdate == null) return null;
    final now = DateTime.now();
    int years = now.year - birthdate!.year;
    if (now.month < birthdate!.month ||
        (now.month == birthdate!.month && now.day < birthdate!.day)) {
      years--;
    }
    return years;
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'birthdate': birthdate?.toIso8601String(),
      'address': address,
      'phoneNumber': phoneNumber,
      'profileImageBase64': profileImageBase64,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      birthdate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate'] as String)
          : null,
      address: json['address'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      profileImageBase64: json['profileImageBase64'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserProfile.decode(String source) =>
      UserProfile.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

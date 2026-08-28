enum UserRole { customer, merchant, driver, admin, ceo, support, finance }

class Profile {
  const Profile({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    this.vehicle,
  });

  final String id;
  final String phone;
  final String name;
  final UserRole role;
  final String? vehicle;

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.customer,
    ),
    vehicle: json['vehicle'] as String?,
  );

  /// §4 wire serialization.
  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'name': name,
    'role': role.name,
    if (vehicle != null) 'vehicle': vehicle,
  };
}

class Session {
  const Session({required this.token, required this.profile});
  final String token;
  final Profile profile;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    token: json['token'] as String? ?? '',
    profile: Profile.fromJson(Map<String, dynamic>.from(json['profile'] as Map? ?? const {})),
  );

  /// §4 wire serialization.
  Map<String, dynamic> toJson() => {'token': token, 'profile': profile.toJson()};
}
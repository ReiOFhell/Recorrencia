import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({required super.id, required super.displayName, required super.role});

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        id: map['id'] as String,
        displayName: (map['display_name'] ?? '') as String,
        role: (map['role'] ?? 'observer') as String,
      );
}

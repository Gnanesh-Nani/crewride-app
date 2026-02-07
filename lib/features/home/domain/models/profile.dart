class Profile {
  final String id;
  final String status;
  final ProfileData profileData;

  Profile({required this.id, required this.status, required this.profileData});

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? '',
      status: json['status'] ?? '',
      profileData: ProfileData.fromJson(json['profile'] ?? {}),
    );
  }
}

class ProfileData {
  final String userName;
  final String fullName;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? bikeModel;
  final String? bikeNumber;
  final String? bio;
  final DateTime createdAt;

  ProfileData({
    required this.userName,
    required this.fullName,
    this.avatarUrl,
    this.bannerUrl,
    this.bikeModel,
    this.bikeNumber,
    this.bio,
    required this.createdAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userName: json['userName'] ?? '',
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
      bannerUrl: json['bannerUrl'],
      bikeModel: json['bikeModel'],
      bikeNumber: json['bikeNumber'],
      bio: json['bio'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

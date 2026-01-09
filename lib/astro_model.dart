class Astrologer {
  final int id;
  final int userId;
  final String name;
  final String? email;
  final String? mobile;
  final String? gender;
  final String? skills;
  final String? language;
  final double videoCallCharge;
  final double audioCallCharge;
  final bool isOnline;
  final double chatCharge;
  final int? experience;
  final String? education;
  final String? bio;
  final String? image;
  final int? adminCommission;
  final int? status;

  Astrologer({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.mobile,
    this.gender,
    this.skills,
    this.language,
    required this.videoCallCharge,
    required this.audioCallCharge,
    required this.isOnline,
    required this.chatCharge,
    this.experience,
    this.education,
    this.bio,
    this.image,
    this.adminCommission,
    this.status,
  });

  factory Astrologer.fromMap(Map<String, dynamic> map) {
    return Astrologer(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      email: map['email'] as String?,
      mobile: map['mobile'] as String?,
      gender: map['gender'] as String?,
      skills: map['skills'] as String?,
      language: map['language'] as String?,
      videoCallCharge:
          double.tryParse(map['video_call_charge']?.toString() ?? '0') ?? 0,
      audioCallCharge:
          double.tryParse(map['audio_call_charge']?.toString() ?? '0') ?? 0,
      isOnline: map['is_online'] == 1 || map['is_online'] == true,
      chatCharge: double.tryParse(map['chat_charge']?.toString() ?? '0') ?? 0,
      experience: map['experience'] as int?,
      education: map['education'] as String?,
      bio: map['bio'] as String?,
      image: map['image'] as String?,
      adminCommission: map['admin_commission'] as int?,
      status: map['status'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'gender': gender,
      'skills': skills,
      'language': language,
      'video_call_charge': videoCallCharge,
      'audio_call_charge': audioCallCharge,
      'is_online': isOnline ? 1 : 0,
      'chat_charge': chatCharge,
      'experience': experience,
      'education': education,
      'bio': bio,
      'image': image,
      'admin_commission': adminCommission,
      'status': status,
    };
  }
}

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum AvatarType { initials, emoji, generated, uploaded }

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final PrivacyConsent privacyConsent;
  final String? avatarData;
  final AvatarType avatarType;
  final int? backgroundColor;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.privacyConsent = const PrivacyConsent(),
    this.avatarData,
    this.avatarType = AvatarType.initials,
    this.backgroundColor,
  });

  // Create a UserModel from a Firebase User
  factory UserModel.fromFirebaseUser(firebase_auth.User user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  // Create a copy of this UserModel with some updated properties
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    PrivacyConsent? privacyConsent,
    String? avatarData,
    AvatarType? avatarType,
    int? backgroundColor,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      privacyConsent: privacyConsent ?? this.privacyConsent,
      avatarData: avatarData ?? this.avatarData,
      avatarType: avatarType ?? this.avatarType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  // Convert UserModel to Map for Firestore or local storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'privacyConsent': privacyConsent.toMap(),
      'avatarData': avatarData,
      'avatarType': avatarType.name,
      'backgroundColor': backgroundColor,
    };
  }

  // Create a UserModel from a Map (from Firestore or local storage)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      privacyConsent:
          map['privacyConsent'] != null
              ? PrivacyConsent.fromMap(map['privacyConsent'])
              : const PrivacyConsent(),
      avatarData: map['avatarData'],
      avatarType:
          map['avatarType'] != null
              ? AvatarType.values.firstWhere(
                (type) => type.name == map['avatarType'],
                orElse: () => AvatarType.initials,
              )
              : AvatarType.initials,
      backgroundColor: map['backgroundColor'],
    );
  }
}

class PrivacyConsent {
  final bool analyticsConsent;
  final bool thirdPartyShareConsent;
  final DateTime? lastUpdated;

  const PrivacyConsent({
    this.analyticsConsent = false,
    this.thirdPartyShareConsent = false,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'analyticsConsent': analyticsConsent,
      'thirdPartyShareConsent': thirdPartyShareConsent,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory PrivacyConsent.fromMap(Map<String, dynamic> map) {
    return PrivacyConsent(
      analyticsConsent: map['analyticsConsent'] ?? false,
      thirdPartyShareConsent: map['thirdPartyShareConsent'] ?? false,
      lastUpdated:
          map['lastUpdated'] != null
              ? DateTime.parse(map['lastUpdated'])
              : null,
    );
  }

  PrivacyConsent copyWith({
    bool? analyticsConsent,
    bool? thirdPartyShareConsent,
    DateTime? lastUpdated,
  }) {
    return PrivacyConsent(
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      thirdPartyShareConsent:
          thirdPartyShareConsent ?? this.thirdPartyShareConsent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Academic position/year - kept as a simple enum so the UI
/// can offer a fixed dropdown instead of free text.
enum AcademicPosition {
  bachelor1,
  bachelor2,
  bachelor3,
  master1,
  master2,
  phd,
  alumni,
}

extension AcademicPositionLabel on AcademicPosition {
  String get label {
    switch (this) {
      case AcademicPosition.bachelor1:
        return 'Bachelor - 1st year';
      case AcademicPosition.bachelor2:
        return 'Bachelor - 2nd year';
      case AcademicPosition.bachelor3:
        return 'Bachelor - 3rd year';
      case AcademicPosition.master1:
        return 'Master - 1st year';
      case AcademicPosition.master2:
        return 'Master - 2nd year';
      case AcademicPosition.phd:
        return 'PhD';
      case AcademicPosition.alumni:
        return 'Alumni';
    }
  }
}

enum Sex { male, female, preferNotToSay }

extension SexLabel on Sex {
  String get label {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.preferNotToSay:
        return 'Prefer not to say';
    }
  }
}

class User {
  final String id;
  final String email;

  // Profile fields - null/empty until the user completes profile setup.
  final String? name;
  final String? surname;
  final String? university;
  final String? country; // one of kStandardizedCountries (lib/data/countries.dart)
  final String? city; // one of kCitiesByCountry[country] (lib/data/cities.dart)
  final AcademicPosition? position;
  final int? age;
  final String? photoUrl;
  final List<String> languages;
  final Sex? sex;

  // Whether this user is currently open to being matched as a buddy -
  // a standing status the user toggles, not tied to any single request.
  final bool isAcceptingBuddyRequests;

  User({
    required this.id,
    required this.email,
    this.name,
    this.surname,
    this.university,
    this.country,
    this.city,
    this.position,
    this.age,
    this.photoUrl,
    this.languages = const [],
    this.sex,
    this.isAcceptingBuddyRequests = false,
  });

  /// True once the extra profile info has been filled in.
  /// Used to decide: send user to ProfileSetupScreen or straight to MainScreen.
  bool get hasCompletedProfile => name != null && name!.isNotEmpty && surname != null && surname!.isNotEmpty;

  String get fullName => [name, surname].where((s) => s != null && s.isNotEmpty).join(' ');

  User copyWith({
    String? name,
    String? surname,
    String? university,
    String? country,
    String? city,
    AcademicPosition? position,
    int? age,
    String? photoUrl,
    List<String>? languages,
    Sex? sex,
    bool? isAcceptingBuddyRequests,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      university: university ?? this.university,
      country: country ?? this.country,
      city: city ?? this.city,
      position: position ?? this.position,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      languages: languages ?? this.languages,
      sex: sex ?? this.sex,
      isAcceptingBuddyRequests: isAcceptingBuddyRequests ?? this.isAcceptingBuddyRequests,
    );
  }

  /// Converts to a map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'surname': surname,
      'university': university,
      'country': country,
      'city': city,
      'position': position?.name, // store enum as its string name
      'age': age,
      'photoUrl': photoUrl,
      'languages': languages,
      'sex': sex?.name,
      'isAcceptingBuddyRequests': isAcceptingBuddyRequests,
    };
  }

  /// Builds a User from a Firestore document map.
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String?,
      surname: map['surname'] as String?,
      university: map['university'] as String?,
      country: map['country'] as String?,
      city: map['city'] as String?,
      position: _positionFromString(map['position'] as String?),
      age: map['age'] as int?,
      photoUrl: map['photoUrl'] as String?,
      languages: (map['languages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sex: _sexFromString(map['sex'] as String?),
      isAcceptingBuddyRequests: map['isAcceptingBuddyRequests'] as bool? ?? false,
    );
  }

  static AcademicPosition? _positionFromString(String? value) {
    if (value == null) return null;
    for (final e in AcademicPosition.values) {
      if (e.name == value) return e;
    }
    return null;
  }

  static Sex? _sexFromString(String? value) {
    if (value == null) return null;
    for (final e in Sex.values) {
      if (e.name == value) return e;
    }
    return null;
  }
}
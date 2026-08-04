class User {
  int? id;
  String name;
  String surname;
  String middleName;
  String birthday;
  String username;
  String password;
  String validIdPath;

  User({
    this.id,
    required this.name,
    required this.surname,
    required this.middleName,
    required this.birthday,
    required this.username,
    required this.password,
    required this.validIdPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'middleName': middleName,
      'birthday': birthday,
      'username': username,
      'password': password,
      'validIdPath': validIdPath,
    };
  }
}